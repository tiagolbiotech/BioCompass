import re
import pandas as pd
from sys import argv
import os
import os.path

script, genome, input_path, path_to_edges = argv


gbk_list = []
for root, dirs, files in os.walk("%s"%input_path):
    for file in files:
        if file.endswith(".gbk"):
             gbk_list.append(os.path.join(root, file))

cluster_list = []
for root, dirs, files in os.walk("%s/clusterblast"%input_path):
    for file in files:
        if file.endswith(".txt"):
             cluster_list.append(os.path.join(root, file))

filename = '%s/merged_edges_best_itineration.txt'%path_to_edges

if os.path.isfile(filename):
    edges_df = pd.read_csv(filename, sep='\t')
    hits_list = edges_df['BLAST_hit'].drop_duplicates(inplace=False)
    hits_list = hits_list.tolist()
    col1 = []
    col2 = []
    for item in cluster_list:
        cluster_num = re.search(r'(.*)cluster(\d*).txt',item).group(2)
        cluster_num = '{0}'.format('%s'%cluster_num.zfill(3))
        cluster_name = '%s_%s'%(genome,cluster_num)
        if cluster_name in hits_list:
            col1.append(item)
            for gbk in gbk_list:
                m = re.search(r'(.*).cluster%s.gbk'%cluster_num,gbk)
                if m:
                    col2.append(m.group(0))
    frames = {'cluster':col1,'gbk':col2}
    output_df = pd.DataFrame(frames, index=None)
    output_handle = open('excluce_list.txt', "w")
    output_df.to_csv(output_handle, sep='\t', index=False)
    output_handle.close()


