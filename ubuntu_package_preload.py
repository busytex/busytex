import os
import sys
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

def generate_preload(texmf_src, package_file_list, skip_log, texmf_dst = '/texmf', texmf_ubuntu = '/usr/share/texlive', texmf_dist = '/usr/share/texlive/texmf-dist'):
    preload = set()
    print(f'Skip log in [{skip_log or "stderr"}]', file = sys.stderr)
    if skip_log:
        os.makedirs(os.path.dirname(args.skip_log), exist_ok = True)
        preload.add((skip_log, os.path.join('/var/log', os.path.basename(skip_log))))
        skip_log = open(skip_log, 'w')
    else:
        skip_log = sys.stderr

    for path in package_file_list:
        if not path.startswith(texmf_dist):
            print(path, file = skip_log)
            continue

        dirname = os.path.dirname(path)
        src_path = path.replace(texmf_ubuntu, texmf_src)

        if not os.path.exists(src_path):
            print(path, file = skip_log)
            continue
        
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
    args = parser.parse_args()

    filelist_url = os.path.join(args.url, 'all', args.package, 'filelist')
    page = urllib.request.urlopen(filelist_url).read().decode('utf-8')
    
    html_parser = UbuntuDebFileList()
    html_parser.feed(page)
    preload = generate_preload(args.texmf, html_parser.file_list, args.skip_log)

    print(' '.join(f'--preload {src}@{dst}' for src, dst in preload))
