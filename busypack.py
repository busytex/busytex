use strict;
use warnings;
use Getopt::Long;
use File::Path;
use File::Find;
use File::Spec;
use Cwd;

my $input_path = '';
my $output_path = '';
my $prefix = '';
my $ld = 'ld';
my $skip = '';
Getopt::Long::GetOptions(
    'input-path|i=s'  => \$input_path,
    'output-path|o=s' => \$output_path,
    'prefix=s'        => \$prefix,
    'ld=s'            => \$ld,
    'skip=s'          => \$skip
);
die "Input path does not exist or is not a directory" unless -e $input_path && -d $input_path ;
die "Output path not specified" if $output_path eq '';

File::Path::make_path($output_path . '.o');

my $oldcwd = Cwd::getcwd();
my (@objects, @files, @dirs_relpaths, @safepaths, @relpaths);
File::Find::find(sub {
    my $newcwd = Cwd::getcwd(); chdir $oldcwd; 
    my $p = $File::Find::name;
    my $safepath = $p; $safepath =~ s/[\/.-]/_/g;
    my $relpath = (split(/\//, $p, 2))[-1];

    if (-d $p) {
        push @dirs_relpaths, $p;
    } elsif ($skip eq '' or $p !~ /$skip\z/) {
        push @files, $p;
        push @safepaths, $safepath;
        push @relpaths, $relpath;
        push @objects, File::Spec->catfile($output_path . '.o', $safepath . '.o');
        system($ld, '-r', '-b', 'binary', '-o', $objects[-1], $files[-1]) == 0 or die "ld command failed: $?";
    }
    chdir $newcwd;
}, $input_path);

# problem: can produce the same symbol name because of this mapping

open my $g, '>', $output_path . '.txt' or die;
print $g join("\n", @objects);

open my $f, '>', $output_path or die;
print $f "size_t packfs_builtin_files_num = ", scalar(@files), ";\n\n";
print $f join("\n", map { "extern char _binary_${_}_start[], _binary_${_}_end[];" } @safepaths), "\n\n";

print $f "const char* packfs_builtin_safepaths[] = {\n\"", join("\",\n\"", @safepaths), "\"\n};\n";
print $f "const char* packfs_builtin_abspaths[] = {\n\"" , join("\",\n\"", map { File::Spec->catfile($prefix, $_) } @relpaths), "\"\n};\n\n";
print $f "const char* packfs_builtin_starts[] = {\n", join("\n", map { "_binary_${_}_start," } @safepaths), "\n};\n\n";
print $f "const char* packfs_builtin_ends[] = {\n", join("\n", map { "_binary_${_}_end," } @safepaths), "\n};\n\n";
