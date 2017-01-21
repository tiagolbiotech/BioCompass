#!/bin/bash

binpath=`pwd`
cd ..
rootpath=`pwd`
cd $binpath

my_db=`echo /Users/Tiago/Desktop/BioCompass/my_database_clusters`

#first, we need to list the inputs in the descending order for to the number of BGCs
find ../antiSMASH_input -maxdepth 1 -mindepth 1 -type d -exec sh -c "fc=\$(find '{}' -name "*cluster*.gbk" \
 | wc -l); echo \"\$fc\t{}\"" \; | sort -nr | cut -d / -f3 > genome_list.txt

# #before executing BioCompass, we need to rename all gbk files at the inputs 
# # in order to insert their cluster number in the accession field
# for i in `cat genome_list.txt`; do
# 	genome=$i
# 	gbk_list=`ls $rootpath/antiSMASH_input/$genome/*cluster*.gbk | xargs -n1 basename | cat`
# 	for j in $gbk_list; do
# 		python rename_gbk.py $rootpath/antiSMASH_input/$genome/$j $genome
# 	done
# done

#now, we can execute BioCompass for each input, using the following loop
for i in `cat genome_list.txt`; do
	genome=$i
	gbk_list=`ls $rootpath/antiSMASH_input/$genome/*cluster*.gbk | xargs -n1 basename | cat`
	cp $rootpath/antiSMASH_input/**/*cluster*.gbk $my_db
	if [ ! -d $rootpath/merged_results ]; then mkdir -p $rootpath/merged_results; fi
	python check_missing_clusters.py $genome $rootpath/antiSMASH_input/$genome \
		$rootpath/merged_results/
	if [ -s $rootpath/BioCompass/exclude_list.txt ]; then \
		while IFS= read -r line; \
		    do case "$line" in 'cluster'*) continue ;; esac; \
			file1=`echo $line | awk '{print $1}'`
			mv $file1 $file1.no
			file2=`echo $line | awk '{print $2}'`
			mv $file2 $file2.no
	        done < $rootpath/BioCompass/exclude_list.txt;
	fi
	rm $rootpath/BioCompass/exclude_list.txt
	make INPUTDIR='/Users/Tiago/Desktop/BioCompass/antiSMASH_input' REFNAME=$genome \
		MULTIGENEBLASTDIR='/Users/Tiago/Desktop/BioCompass/multigeneblast' CUSTOMDB=$my_db PART1
	for j in $gbk_list; do
		rm $rootpath/outputs/database_clusters/$j
	done
	corrupted=`find $rootpath/outputs/database_clusters -type f -print | \
		xargs grep "^\?\n\?$" | sort -u | awk -F':' '{print $1}'`
	if [ ! -d $rootpath/merged_results/corrupted_files ]; then mkdir -p $rootpath/merged_results/corrupted_files; \
	    mv $corrupted $rootpath/merged_results/corrupted_files ; else mv $corrupted $rootpath/merged_results/corrupted_files; fi
	make INPUTDIR='/Users/Tiago/Desktop/BioCompass/antiSMASH_input' REFNAME=$genome \
		MULTIGENEBLASTDIR='/Users/Tiago/Desktop/BioCompass/multigeneblast' CUSTOMDB=$my_db ALL
	[ -f $rootpath/merged_results/merged_edges_best_itineration.txt ] && tail -n +2 \
		$rootpath/outputs/mgb_result/*_edges_best_itineration.txt >> $rootpath/merged_results/merged_edges_best_itineration.txt \
		|| cat $rootpath/outputs/mgb_result/*_edges_best_itineration.txt > $rootpath/merged_results/merged_edges_best_itineration.txt
	mv $rootpath/outputs $rootpath/outputs_$genome
	mv $rootpath/outputs_$genome/database_clusters/*.gbk $my_db
	# rm -r $rootpath/outputs_$genome/database_clusters/
done

##rename all files back to normal:
# for file in $(find ../antiSMASH_input/ -name "*.no")
# do 
#   mv $file `echo $file | sed s/.no//`
# done


