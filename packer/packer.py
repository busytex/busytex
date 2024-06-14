import os
import io
import glob
import tarfile


def packerTex(archivePath, outputPath, archiveType='7z'):
    if archiveType == '7z':
        import py7zr

    # check if the archive path exists
    if not os.path.exists(archivePath):
        raise Exception("archivePath does not exist")

    # check if the output path exists, if not, create it
    if not os.path.exists(outputPath):
        os.makedirs(outputPath, exist_ok=True)

    # read all filenames or archive
    filenames = glob.glob(os.path.join(archivePath)+"/*.tar.xz")

    # filter, so '.doc.' files are not included
    filenames = list(filter(lambda fn: '.doc.' not in fn, filenames))

    # sort by name
    filenames = sorted(filenames)
    
    # now the filenames should always be
    # ['package1.r****.tar.xz, package1.source.r****.tar.xz, package2...]

    for i in range(0, len(filenames), 2):
        # extract name of package
        packageName = os.path.basename(filenames[i])
        packageName = packageName[0:packageName.index('.')]
        print(packageName)

        # load files and put it into 7z archive
        fileContent = {}
        for j in range(2):
            with tarfile.open(filenames[i+j], "r:xz") as tar:
                for member in tar:
                    if not member.name.startswith('tlpkg'):
                        fileContent[member.name] = tar.extractfile(member).read()
        
        if archiveType == '7z':
            with py7zr.SevenZipFile(outputPath+'/'+packageName+'.7z', 'w') as archive:
                for key in fileContent:
                    archive.writef(io.BytesIO(fileContent[key]), key)

        elif archiveType == 'tar.xz':
            with tarfile.open(outputPath+'/'+packageName+'.tar.xz', "w:xz") as archive:
                for key in fileContent:
                    member = tarfile.TarInfo(key)
                    member.size = len(fileContent[key])
                    archive.addfile(member, fileobj=io.BytesIO(fileContent[key]))
        
    # finished with convert
    return True

if __name__ == "__main__":
    packerTex("texlive/archive/", "output", "7z")
    packerTex("texlive/archive/", "output", "tar.xz")