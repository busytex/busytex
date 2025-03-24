import os
import re
import argparse
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--input-path', '-i')
parser.add_argument('--output-path', '-o')
parser.add_argument('--prefix')
parser.add_argument('--ld', default = 'ld')
parser.add_argument('--include', default = '')
parser.add_argument('--exclude', default = '')
args = parser.parse_args()

assert args.input_path and os.path.exists(args.input_path) and os.path.isdir(args.input_path), "Input path does not exist or is not a directory"
assert args.output_path, "Output path not specified"

# problem: can produce the same symbol name because of this mapping, ld maps only to _, so may need to rename the file before invoking ld
translate = {ord('.') : '_', ord('-') : '__', ord('_') : '__', ord('/') : '_'}

output_path_o = args.output_path + '.o'
os.makedirs(output_path_o, exist_ok = True)
objects, safepaths, relpaths, relpaths_dirs  = [], [], [], ['']

cwd = os.getcwd()
for (dirpath, dirnames, filenames) in os.walk(args.input_path):
    relpaths_dirs.extend(os.path.join(dirpath, basename).removeprefix(args.input_path).lstrip(os.path.sep) for basename in dirnames)
    
    for basename in filenames:
        p = os.path.join(dirpath, basename)
        relpath = p.removeprefix(args.input_path).lstrip(os.path.sep)
        safepath = relpath.translate(translate)

        include_file = True
        if args.include and re.match('.+(' + args.include + ')$', p):
            include_file = True
        elif args.exclude and re.match('.+(' + args.exclude + ')$', p):
            include_file = False
        elif relpath.endswith('.o'):
            include_file = False
        
        if include_file:
            safepaths.append(safepath)
            relpaths.append(relpath)
            objects.append(os.path.join(output_path_o, safepath + '.o'))
            abspath_o = os.path.join(os.path.abspath(output_path_o), safepath + '.o')
            output_path_o_safepath = os.path.join(output_path_o, safepath)
            
            os.symlink(os.path.abspath(p), output_path_o_safepath)
            subprocess.check_call([args.ld, '-r', '-b', 'binary', '-o', abspath_o, safepath], cwd = output_path_o)
            os.unlink(output_path_o_safepath)

g = open(args.output_path + '.txt', 'w')
print('\n'.join(objects), file = g)
f = open(args.output_path, 'w')
print("size_t packfs_builtin_files_num = ", len(relpaths), ', packfs_builtin_dirs_num = ', len(relpaths_dirs), ";\n\n", file = f)
print("const char* packfs_builtin_abspaths[] = {\n\"" , "\",\n\"".join(os.path.join(args.prefix, _) for _ in relpaths), "\"\n};\n\n", sep = '', file = f)
print("const char* packfs_builtin_abspaths_dirs[] = {\n\"" , "\",\n\"".join(os.path.join(args.prefix, _).rstrip('/') for _ in relpaths_dirs), "\"\n};\n\n", sep = '', file = f)
print("\n".join(f"extern char _binary_{_}_start[], _binary_{_}_end[];" for _ in safepaths), "\n\n", file = f)
print("const char* packfs_builtin_starts[] = {\n", "\n".join(f"_binary_{_}_start," for _ in safepaths), "\n};\n\n", file = f)
print("const char* packfs_builtin_ends[] = {\n", "\n".join(f"_binary_{_}_end," for _ in safepaths), "\n};\n\n", file = f)
