import os
import re
import argparse
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--input-path', '-i')
parser.add_argument('--output-path', '-o')
parser.add_argument('--prefix')
parser.add_argument('--ld', default = 'ld')
parser.add_argument('--skip', default = '')
args = parser.parse_args()

assert args.input_path and os.path.exists(args.input_path) and os.path.isdir(args.input_path), "Input path does not exist or is not a directory"
assert args.output_path, "Output path not specified"

os.makedirs(args.output_path + '.o', exist_ok = True)

objects, files, dirs_relpaths, safepaths, relpaths = [], [], [], [], []

for (dirpath, dirnames, filenames) in os.walk(args.input_path):
    dirs_relpaths.extend(os.path.join(dirpath, basename).split(os.path.sep, maxsplit = 1)[-1] for basename in dirnames)
    
    for basename in filenames:
        p = os.path.join(dirpath, basename)
        safepath = p.translate({ord('.') : '_', ord('-') : '_', ord('/') : '_'})
        
        relpath = p.split(os.path.sep, maxsplit = 1)[-1]
        if not args.skip or not re.match('.+(' + args.skip + ')$', basename):
            files.append(p)
            safepaths.append(safepath)
            relpaths.append(relpath)
            objects.append(os.path.join(args.output_path + '.o', safepath + '.o'))
            os.makedirs(os.path.dirname(objects[-1]), exist_ok = True)
            subprocess.check_call([args.ld, '-r', '-b', 'binary', '-o', objects[-1], files[-1]])

# problem: can produce the same symbol name because of this mapping

g = open(args.output_path + '.txt', 'w')
print('\n'.join(objects), file = g)

f = open(args.output_path, 'w')
print("size_t packfs_builtin_files_num = ", len(files), ";\n\n", file = f)
print("\n".join(f"extern char _binary_{_}_start[], _binary_{_}_end[];" for _ in safepaths), "\n\n", file = f)
print("const char* packfs_builtin_safepaths[] = {\n\"", "\",\n\"".join(safepaths), "\"\n};\n", file = f)
print("const char* packfs_builtin_abspaths[] = {\n\"" , "\",\n\"".join(os.path.join(args.prefix, _) for _ in relpaths), "\"\n};\n\n", file = f)
print("const char* packfs_builtin_starts[] = {\n", "\n".join(f"_binary_{_}_start," for _ in safepaths), "\n};\n\n", file = f)
print("const char* packfs_builtin_ends[] = {\n", "\n".join(f"_binary_{_}_end," for _ in safepaths), "\n};\n\n", file = f)
