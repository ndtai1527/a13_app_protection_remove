import sys
from configobj import ConfigObj

def lineNumByPhrase(phrase, source, isText=0, startsAt=0):
    if isText:
        if isText == 1 or isText == True:
            source = source.splitlines()
        for (i, line) in enumerate(source):
            if i >= startsAt and phrase in line.strip():
                return i
    else:
        with open(source, 'r') as f:
            return lineNumByPhrase(phrase, f, 2, startsAt)
    return -1

def fileReplaceRange(filename, startIndex, endIndex, content):
    lines = []
    with open(filename, 'r') as f:
        lines = f.readlines()

    with open(filename, 'w') as f:
        wrote = False
        for i, line in enumerate(lines):
            if i < startIndex or i > endIndex:
                f.write(line)
            elif not wrote:
                f.write(content + '\n')
                wrote = True

# Main script
if __name__ == "__main__":
    if len(sys.argv) > 2:
        ini = ConfigObj(str(sys.argv[1]))
        config = ini['main']
        replaceFile = str(sys.argv[2])
        phraseStart = config['phraseStart'].strip()
        phraseEnd = config['phraseEnd'].strip()
        replaceWith = config['replaceWith']
        
        startIndex = lineNumByPhrase(phraseStart, replaceFile)
        endIndex = lineNumByPhrase(phraseEnd, replaceFile, 0, startIndex)
        
        if startIndex != -1 and endIndex != -1:
            fileReplaceRange(replaceFile, startIndex, endIndex, replaceWith)
        else:
            print("Error: Could not find specified phrases in the file.")
    else:
        print("Usage: script.py <config_file> <file_to_replace>")
