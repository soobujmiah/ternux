#!/usr/bin/env python3
"""Stream one known QNN archive member into a read-only anonymous FD.

The original archive remains in place. No extracted model file is written.
This validates model input transport only; it does not perform inference.
"""
import argparse
import fcntl
import hashlib
import json
import os
import subprocess
import zipfile
from contextlib import contextmanager

MEMBERS = {
    'tokenizer.json', 'clip_v2.mnn', 'pos_emb.bin', 'token_emb.bin',
    'vae_encoder.bin', 'vae_decoder.bin', 'unet.bin',
}
PREFIX = 'output_512/qnn_models_8gen2/'
MAX_MEMBER_BYTES = 1536 * 1024 * 1024


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
    parser.add_argument('--execute-htp', action='store_true', help='run bounded VAE graph twice with fixed raw input')
    parser.add_argument('--runtime-dir', help='absolute path to licensed Android QNN runtime libraries in scratch')
    args = parser.parse_args()
    if (args.load_htp or args.execute_htp) and not args.inspect_helper:
        parser.error('HTP operations require --inspect-helper')
    if args.load_htp and args.execute_htp:
        parser.error('choose one HTP operation')
    if args.execute_htp and args.member != 'vae_encoder.bin':
        parser.error('--execute-htp is only supported for vae_encoder.bin')
    if args.runtime_dir and (not os.path.isabs(args.runtime_dir) or not os.path.isdir(args.runtime_dir)):
        parser.error('--runtime-dir must name an existing absolute directory')
    try:
        with member_fd(args.archive, args.member) as (fd, evidence):
            if os.fstat(fd).st_size != evidence['bytes']:
                raise ValueError('anonymous FD size mismatch')
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
                if args.load_htp or args.execute_htp:
                    command.append('--execute-htp' if args.execute_htp else '--load-htp')
                result = subprocess.run(command,
                                        pass_fds=(fd,), env=env,
                                        timeout=120 if args.execute_htp else 30)
                if result.returncode:
                    print(json.dumps({'stage': 'android_helper_exit', 'returncode': result.returncode}))
                    return 2
        return 0
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        print(json.dumps({'stage': 'archive_input_error', 'error': str(exc)}))
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
