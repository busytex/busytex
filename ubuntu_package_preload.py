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

def generate_preload(texmf_src, package_file_list, texmf_dst = '/texmf', texmf_ubuntu = '/usr/share/texlive', texmf_dist = '/usr/share/texlive/texmf-dist'):
    preload = set()
    for path in package_file_list:
        if not path.startswith(texmf_dist):
            print(f'Skipping [{path}]', file = sys.stderr)
            continue

        dirname = os.path.dirname(path)
        src_path = path.replace(texmf_ubuntu, texmf_src)

        if not os.path.exists(src_path):
            print(f'Skipping [{path}]', file = sys.stderr)
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
    args = parser.parse_args()

    filelist_url = os.path.join(args.url, 'all', args.package, 'filelist')
    page = urllib.request.urlopen(filelist_url).read().decode('utf-8')
    
    html_parser = UbuntuDebFileList()
    html_parser.feed(page)
    preload = generate_preload(args.texmf, html_parser.file_list)

    print(' '.join(f'--preload {src}@{dst}' for src, dst in preload))
