import os
import shutil
import argparse

def traverse_and_copy(tgt_dir, preload):
    res_dirs, res_files = set(), set()
    for src_path, dst_path in preload:
        tgt_path = os.path.join(tgt_dir, dst_path.lstrip('/'))
        os.makedirs(os.path.dirname(tgt_path), exist_ok = True)
        
        splitted = dst_path.split(os.sep)[:-1]
        d = os.sep
        for s in splitted:
            d = os.path.join(d, s)
            res_dirs.add(d)
        
        if os.path.isfile(src_path):
            print(f'Processing file [{src_path}]')
            res_files.add(dst_path)
            shutil.copy2(src_path, tgt_path)
        else:
            print(f'Processing directory [{src_path}]')
            for root, dirs, files in os.walk(src_path, topdown = True):
                res_dirs.add(root.replace(src_path, dst_path))
                res_dirs.update(os.path.join(root.replace(src_path, dst_path), name) for name in dirs)
                res_files.update(os.path.join(root.replace(src_path, dst_path), name) for name in files)
            shutil.copytree(src_path, tgt_path)
    
    return list(sorted(res_dirs)), list(sorted(res_files))

def main(data_file, js_output, export_name, preload):
    dirs, files = traverse_and_copy(data_file, preload)
    
    f = open(js_output, 'w')
    f.write(f'''var Module = typeof {export_name} !== 'undefined' ? {export_name}''' + ' : {};')
    f.write('(function() {\n')
    f.write('function runWithFS() { const FS = Module.FS, R = Module.locateFile("/"); const M = p => FS.analyzePath(p).exists ? null : FS.mkdir(p), F = (dst_dir, dst_name, dst_path) => FS.analyzePath(dst_dir + "/" + dst_name).exists ? null : FS.createLazyFile(dst_dir, dst_name, R + dst_path, true, false);\n')
    f.writelines(f'M("{dst_dir}");\n' for dst_dir in dirs)
    f.writelines(f'F("{dst_dir}", "{dst_name}", "{dst_path}");\n' for dst_path in files for dst_dir, dst_name in [(os.path.dirname(dst_path), os.path.basename(dst_path))])
    f.write('}\n')
    f.write('''
    if (Module['calledRun']) {
      runWithFS();
    } else {
      if (!Module['preRun']) Module['preRun'] = [];
      Module["preRun"].push(runWithFS); // FS is not initialized yet, wait for it
    }''')
    f.write('})();')
    print(f'Written to [{js_output}]')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('data_file')
    parser.add_argument('--preload', action = 'append', type = lambda s: s.split('@'))
    parser.add_argument('--js-output', required = True)
    parser.add_argument('--export-name', required = True)
    args, unknownargs = parser.parse_known_args()

    main(**vars(args))
