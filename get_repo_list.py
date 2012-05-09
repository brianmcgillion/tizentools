#!/usr/bin/python

import urllib2, os
from BeautifulSoup import BeautifulSoup
from optparse import OptionParser
import xml.etree.ElementTree as xml

# The typical git web view is a table with each row representing a repo
# the column headers that are being parsed are.
# Project    Description    Owner   Last Change  [links...]
# We are only concerned with the project column which specifies the project
# name
def getRepoNames(projectBaseUrl):
    filenames = []
    #read the raw repo site
    f = urllib2.urlopen(projectBaseUrl)
    raw = f.read()
    # Find the table on the page and extract all the rows from it
    rows = BeautifulSoup(''.join(raw)).find('table').findAll('tr')
    for row in rows:
        cols = row.findAll('td')
        if (len(cols) <= 0):
            continue
        #get the text of the first column without the markup
        path = cols[0].find(text=True)
        #drop the .git extension if it exists
        filename, ext = os.path.splitext(path)
        filenames.append(filename)
    return filenames

def create_xml(name, fetch_url, filenames, useBasename):
    manifest = xml.Element('manifest')
    
    remote = xml.Element('remote')
    remote.attrib['name'] = name
    remote.attrib['fetch'] = fetch_url
    manifest.append(remote)

    default = xml.Element('default')
    default.attrib['revision'] = "master"
    default.attrib['remote'] = name
    manifest.append(default)

    for path in filenames:
        project = xml.Element('project')
        project.attrib['name'] = path
        if useBasename:
            project.attrib['path'] = os.path.basename(path)
        else:
            project.attrib['path'] = path
        manifest.append(project)
    
    return manifest

def writeManifest(output_path, manifest):
    file = open(output_path, 'w')
    xml.ElementTree(manifest).write(file, xml_declaration=True, encoding='utf-8', method="xml")

if __name__ == '__main__':
    parser = OptionParser()
    parser.add_option("-b", "--basename", action="store_true", dest="useBasename", default=False)
    (options, args) = parser.parse_args()

    filenames = getRepoNames("https://review.tizen.org/git")
    manifest = create_xml("tizenorg", "git://review.tizen.org/", filenames, options.useBasename)
    writeManifest("default.xml", manifest)
