#!/usr/bin/env python3
"""Stream one known QNN archive member into a read-only anonymous FD.

The original archive remains in place. No extracted model file is written.
This validates model input transport only; it does not perform inference.
"""
import argparse
from array import array
import fcntl
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import zipfile
import zlib
from contextlib import contextmanager

MEMBERS = {
    'tokenizer.json', 'clip_v2.mnn', 'pos_emb.bin', 'token_emb.bin',
    'vae_encoder.bin', 'vae_decoder.bin', 'unet.bin',
}
PREFIX = 'output_512/qnn_models_8gen2/'
MAX_MEMBER_BYTES = 1536 * 1024 * 1024
DECODER_SHA256 = '42edf1474eea665f593b8c35daf64169da220b6e4095c860eaca494610579ccc'
UNET_SHA256 = '32ab6474a0bf5150f484dc48d68a7db22d56bc9a908edb9620a839daf47c9f60'
DECODER_OUTPUT_BYTES = 1 * 3 * 512 * 512 * 2


def decoder_png(raw):
    """Render the pinned decoder's NCHW UFIXED16 output as an 8-bit RGB PNG."""
    if len(raw) != DECODER_OUTPUT_BYTES or sys.byteorder != 'little':
        raise ValueError('unexpected decoder tensor byte count or host byte order')
    values = array('H')
    values.frombytes(raw)
    width = height = 512
    plane = width * height
    scale, offset = 4.31699882e-05, -35019
    scanlines = bytearray()
    for y in range(height):
        scanlines.append(0)  # PNG filter: none
        for x in range(width):
            pixel = y * width + x
            for channel in range(3):
                real = (values[channel * plane + pixel] + offset) * scale
                scanlines.append(max(0, min(255, round((real + 1.0) * 127.5))))

    def chunk(name, data):
        body = name + data
        return struct.pack('>I', len(data)) + body + struct.pack('>I', zlib.crc32(body))

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    return header + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(scanlines, 6)) + chunk(b'IEND', b'')


@contextmanager
def member_fd(archive_path, member):
    if member not in MEMBERS:
        raise ValueError('member is outside the supported SD1.5 layout')
    fd = -1
    try:
        with zipfile.ZipFile(archive_path) as archive:
            path = PREFIX + member
            entries = [info for info in archive.infolist() if info.filename == path]
            if len(entries) != 1:
                raise ValueError('expected one matching archive member')
            info = entries[0]
            if not 0 < info.file_size <= MAX_MEMBER_BYTES or info.flag_bits & 1:
                raise ValueError('invalid member size or encrypted member')
            fd = os.memfd_create('ternux-qnn-model', os.MFD_CLOEXEC | os.MFD_ALLOW_SEALING)
            digest = hashlib.sha256()
            total = 0
            with archive.open(info) as source:
                while chunk := source.read(1024 * 1024):
                    total += len(chunk)
                    if total > info.file_size:
                        raise ValueError('member exceeds declared size')
                    digest.update(chunk)
                    view = memoryview(chunk)
                    while view:
                        written = os.write(fd, view)
                        if written <= 0:
                            raise OSError('memfd write failed')
                        view = view[written:]
            if total != info.file_size:
                raise ValueError('member size mismatch')
        # ZIP reader verified CRC at EOF. Seals make the completed data immutable.
        seals = fcntl.F_SEAL_WRITE | fcntl.F_SEAL_GROW | fcntl.F_SEAL_SHRINK | fcntl.F_SEAL_SEAL
        fcntl.fcntl(fd, fcntl.F_ADD_SEALS, seals)
        os.lseek(fd, 0, os.SEEK_SET)
        yield fd, {'member': path, 'bytes': total, 'sha256': digest.hexdigest(),
                   'crc_verified': True, 'sealed': True,
                   'on_disk_model_copy': False, 'inference': 'unverified'}
    finally:
        if fd >= 0:
            os.close(fd)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', required=True)
    parser.add_argument('--member', choices=sorted(MEMBERS), required=True)
    parser.add_argument('--inspect-helper', help='existing Android/Bionic context inspector executable')
    parser.add_argument('--load-htp', action='store_true', help='also attempt HTP context load; no graph execution')
    parser.add_argument('--execute-htp', action='store_true', help='run bounded VAE encoder repeat and input-contrast check')
    parser.add_argument('--execute-decoder', action='store_true', help='run pinned VAE decoder with real-zero latent and write a preview PNG')
    parser.add_argument('--execute-unet', action='store_true', help='run pinned UNet twice with fixed sample, timestep and embedding')
    parser.add_argument('--output-png', help='new scratch PNG path for --execute-decoder')
    parser.add_argument('--runtime-dir', help='absolute path to licensed Android QNN runtime libraries in scratch')
    args = parser.parse_args()
    if (args.load_htp or args.execute_htp or args.execute_decoder or args.execute_unet) and not args.inspect_helper:
        parser.error('HTP operations require --inspect-helper')
    if sum((args.load_htp, args.execute_htp, args.execute_decoder, args.execute_unet)) > 1:
        parser.error('choose one HTP operation')
    if args.execute_htp and args.member != 'vae_encoder.bin':
        parser.error('--execute-htp is only supported for vae_encoder.bin')
    if args.execute_decoder and args.member != 'vae_decoder.bin':
        parser.error('--execute-decoder is only supported for vae_decoder.bin')
    if args.execute_unet and args.member != 'unet.bin':
        parser.error('--execute-unet is only supported for unet.bin')
    if bool(args.output_png) != args.execute_decoder:
        parser.error('--output-png is required exactly with --execute-decoder')
    if args.output_png and (not Path(args.output_png).is_absolute() or Path(args.output_png).exists()):
        parser.error('--output-png must be a new absolute path')
    if args.runtime_dir and (not os.path.isabs(args.runtime_dir) or not os.path.isdir(args.runtime_dir)):
        parser.error('--runtime-dir must name an existing absolute directory')
    try:
        with member_fd(args.archive, args.member) as (fd, evidence):
            if os.fstat(fd).st_size != evidence['bytes']:
                raise ValueError('anonymous FD size mismatch')
            if args.execute_decoder and evidence['sha256'] != DECODER_SHA256:
                raise ValueError('decoder context does not match the pinned SHA-256')
            if args.execute_unet and evidence['sha256'] != UNET_SHA256:
                raise ValueError('UNet context does not match the pinned SHA-256')
            evidence['stage'] = 'zip_member_anonymous_fd'
            print(json.dumps(evidence))
            if args.inspect_helper:
                env = os.environ.copy()
                env.pop('LD_PRELOAD', None)
                search_path = '/vendor/lib64:/vendor/lib64/egl:/system/lib64'
                env['LD_LIBRARY_PATH'] = args.runtime_dir + ':' + search_path if args.runtime_dir else search_path
                if args.runtime_dir:
                    env['ADSP_LIBRARY_PATH'] = args.runtime_dir
                command = ['/system/bin/linker64', args.inspect_helper, '--fd', str(fd)]
                output_fd = os.memfd_create('ternux-qnn-decoder-output', os.MFD_CLOEXEC) if args.execute_decoder else -1
                try:
                    if args.execute_decoder:
                        command.extend(('--execute-decoder', '--output-fd', str(output_fd)))
                    elif args.execute_unet:
                        command.append('--execute-unet')
                    elif args.load_htp or args.execute_htp:
                        command.append('--execute-htp' if args.execute_htp else '--load-htp')
                    result = subprocess.run(command,
                                            pass_fds=(fd, output_fd) if output_fd >= 0 else (fd,), env=env,
                                            timeout=120 if args.execute_htp or args.execute_decoder or args.execute_unet else 30)
                    if result.returncode:
                        print(json.dumps({'stage': 'android_helper_exit', 'returncode': result.returncode}))
                        return 2
                    if args.execute_decoder:
                        if os.fstat(output_fd).st_size != DECODER_OUTPUT_BYTES:
                            raise ValueError('decoder output FD has unexpected size')
                        os.lseek(output_fd, 0, os.SEEK_SET)
                        raw = bytearray()
                        while len(raw) < DECODER_OUTPUT_BYTES:
                            chunk = os.read(output_fd, DECODER_OUTPUT_BYTES - len(raw))
                            if not chunk:
                                raise ValueError('decoder output FD ended early')
                            raw.extend(chunk)
                        png = decoder_png(raw)
                        with open(args.output_png, 'xb') as out:
                            out.write(png)
                        print(json.dumps({'stage': 'decoder_preview_png', 'path': args.output_png,
                                          'bytes': len(png), 'sha256': hashlib.sha256(png).hexdigest(),
                                          'raw_sha256': hashlib.sha256(raw).hexdigest(),
                                          'known_output': False, 'full_image_generation': False}))
                finally:
                    if output_fd >= 0:
                        os.close(output_fd)
        return 0
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        print(json.dumps({'stage': 'archive_input_error', 'error': str(exc)}))
        return 2
    except subprocess.TimeoutExpired as exc:
        print(json.dumps({'stage': 'android_helper_timeout', 'seconds': exc.timeout}))
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
