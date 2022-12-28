import os
import sys
import time
import argparse
import urllib.request
import html.parser

class UbuntuDebFileList(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.file_list = None

    def handle_starttag(self, tag, attrs):
        if tag == 'pre':
            self.file_list = []

    def handle_data(self, data):
        if self.file_list == []:
            self.file_list.extend(list(filter(None, data.split('\n'))))

def makedirs_open(path, mode):
    dirname = os.path.dirname(path)
    if dirname:
        os.makedirs(dirname, exist_ok = True)
    return open(path, mode)

def generate_preload(texmf_src, package_file_list, skip, varlog, skip_log = None, good_log = None, providespackage_log = None, texmf_dst = '/texmf', texmf_ubuntu = '/usr/share/texlive', texmf_dist = '/usr/share/texlive/texmf-dist'):
    preload = set()
    print(f'Skip log in [{skip_log or "stderr"}]', file = sys.stderr)
    
    if skip_log:
        preload.add((skip_log, os.path.join(varlog, os.path.basename(skip_log))))
   
    skip_log = makedirs_open(skip_log, 'w')if skip_log else sys.stderr
    providespackage_log = makedirs_open(providespackage_log, 'wb') if providespackage_log else sys.stderr.buffer
    good_log = makedirs_open(good_log, 'w') if good_log else sys.stderr
    
    good_log.writelines(path + '\n' for path in package_file_list)

    for path in package_file_list:
        if any(map(path.startswith, skip)):
            continue

        if not path.startswith(texmf_dist):
            print(path, file = skip_log)
            continue

        dirname = os.path.dirname(path)
        src_path = path.replace(texmf_ubuntu, texmf_src)

        if not os.path.exists(src_path):
            print(path, file = skip_log)
            continue
        
        providespackage_log.writelines(b'//' + line.strip() + b'\n' for line in open(src_path, 'rb') if b'\\ProvidesPackage' in line)

        src_dir = dirname.replace(texmf_ubuntu, texmf_src)
        dst_dir = dirname.replace(texmf_ubuntu, texmf_dst)
        preload.add((src_dir, dst_dir))

    return preload

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--texmf', required = True)
    parser.add_argument('--package', required = True)
    parser.add_argument('--url', required = True)
    parser.add_argument('--skip-log')
    parser.add_argument('--good-log')
    parser.add_argument('--ubuntu-log')
    parser.add_argument('--providespackage-log')
    parser.add_argument('--skip', nargs = '*', default = ['/usr/share/doc', '/usr/share/man'])
    parser.add_argument('--varlog', default = '/var/log')
    parser.add_argument('--retry', type = int, default = 10)
    parser.add_argument('--retry-seconds', type = int, default = 60)
    args = parser.parse_args()

    filelist_url = os.path.join(args.url, 'all', args.package, 'filelist')
    print('File list URL', filelist_url, file = sys.stderr)
    for i in range(args.retry):
        try:
            page = urllib.request.urlopen(filelist_url).read().decode('utf-8')
            break
        except Exception as err:
            assert i < args.retry - 1
            print('Retrying', err, file = sys.stderr)
            time.sleep(args.retry_seconds)
    
    html_parser = UbuntuDebFileList()
    html_parser.feed(page)
    assert html_parser.file_list is not None

    preload = generate_preload(args.texmf, html_parser.file_list, args.skip, skip_log = args.skip_log, good_log = args.good_log, varlog = args.varlog, providespackage_log = args.providespackage_log)

    if args.ubuntu_log:
        makedirs_open(args.ubuntu_log, 'w').writelines(line + '\n' for line in html_parser.file_list)

    print(' '.join(f'--preload {src}@{dst}' for src, dst in preload))
