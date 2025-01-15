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
parser.add_argument('--exclude-executable', action = 'store_true')
args = parser.parse_args()

assert args.input_path and os.path.exists(args.input_path) and os.path.isdir(args.input_path), "Input path does not exist or is not a directory"
assert args.output_path, "Output path not specified"
os.makedirs(args.output_path + '.o', exist_ok = True)
objects, relpaths_dirs, safepaths, relpaths = [], [], [], []

for (dirpath, dirnames, filenames) in os.walk(args.input_path):
    relpaths_dirs.extend(os.path.join(dirpath, basename).removeprefix(args.input_path).lstrip(os.path.sep) for basename in dirnames)
    
    for basename in filenames:
        p = os.path.join(dirpath, basename)
        relpath = p.removeprefix(args.input_path).lstrip(os.path.sep)
        safepath = relpath.translate({ord('.') : '_', ord('-') : '_', ord('_') : '_', ord(os.path.sep) : '_'})
        # problem: can produce the same symbol name because of this mapping

        include_file = True
        if args.include and re.match('.+(' + args.include + ')$', p):
            include_file = True
        elif args.exclude and re.match('.+(' + args.exclude + ')$', p):
            include_file = False
        elif args.exclude_executable and os.access(p, os.X_OK):
            include_file = False
        if include_file:
            safepaths.append(safepath)
            relpaths.append(relpath)
            objects.append(os.path.join(args.output_path + '.o', safepath + '.o'))
            os.makedirs(os.path.dirname(objects[-1]), exist_ok = True)
            # TODO: ln or mv the original file to makethe symbol names unique
            subprocess.check_call([args.ld, '-r', '-b', 'binary', '-o', os.path.abspath(objects[-1]), relpaths[-1]], cwd = args.input_path)

g = open(args.output_path + '.txt', 'w')
print('\n'.join(objects), file = g)
f = open(args.output_path, 'w')
print("size_t packfs_builtin_files_num = ", len(relpaths), ', packfs_builtin_dirs_num = ', len(relpaths_dirs), ";\n\n", file = f)
print("const char* packfs_builtin_abspaths[] = {\n\"" , "\",\n\"".join(os.path.join(args.prefix, _) for _ in relpaths), "\"\n};\n\n", sep = '', file = f)
print("const char* packfs_builtin_abspaths_dirs[] = {\n\"" , "\",\n\"".join(os.path.join(args.prefix, _) for _ in relpaths_dirs), "\"\n};\n\n", sep = '', file = f)
print("\n".join(f"extern char _binary_{_}_start[], _binary_{_}_end[];" for _ in safepaths), "\n\n", file = f)
print("const char* packfs_builtin_starts[] = {\n", "\n".join(f"_binary_{_}_start," for _ in safepaths), "\n};\n\n", file = f)
print("const char* packfs_builtin_ends[] = {\n", "\n".join(f"_binary_{_}_end," for _ in safepaths), "\n};\n\n", file = f)
