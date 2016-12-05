from sys import argv
from Bio import SeqIO
import re

script, gb_file, strain_name = argv


cluster_num = re.search(r'(.*).cluster(\d*).gbk',gb_file).group(2)

gb_record = SeqIO.read(open(gb_file,"r"), "genbank")

gb_record.id = '%s_%s'%(strain_name,cluster_num)

output_handle = open(gb_file, "w")
SeqIO.write(gb_record, output_handle, "genbank")
output_handle.close()