

SHELL = /bin/bash
#TESTING = 1

REFNAME = PAL

ROOT=$(shell cd ../; pwd)

SRC=$(ROOT)/BioCompass
INPUTDIR=$(ROOT)/antiSMASH_input
MULTIGENEBLASTDIR=$(ROOT)/multigeneblast
OUTPUTDIR=$(ROOT)/outputs

MBGDIR=$(OUTPUTDIR)/mgb_result

TABLEDIR=$(OUTPUTDIR)/tables
MAKEDB=$(MULTIGENEBLASTDIR)/makedb.py
MULTIGENEBLAST=$(MULTIGENEBLASTDIR)/multigeneblast.py

ClustersDatabase=$(OUTPUTDIR)/database_clusters
CUSTOMDB=$(ROOT)/my_database_clusters

GBK_INPUT_LIST=$(shell ls $(INPUTDIR)/$(REFNAME)/*cluster*.gbk)
CLUSTER_LIST=$(shell find  $(INPUTDIR)/$(REFNAME)/clusterblast -iname 'cluster*txt')

ifdef TESTING
    ifeq ($(TESTING),1)
        GBK_INPUT_LIST=$(shell ls $(INPUTDIR)/$(REFNAME)/*cluster*.gbk | head -n 2)
        CLUSTER_LIST=$(shell find  $(INPUTDIR)/$(REFNAME)/clusterblast -iname 'cluster*txt' | head -n 2)
    endif
endif

TABLE2_1 = $(foreach v, $(GBK_INPUT_LIST), $(TABLEDIR)/$(REFNAME)_$(shell basename $v | sed -e s/.*cluster// | sed -e s/\.gbk//)_table2_1.csv)
# ============================================================================
.SECONDARY:

help:
	@echo "To run:"
	@echo "make INPUTDIR='path/to/antiSMASH_input' MULTIGENEBLASTDIR='path/to/multigeneblast' ALL; run_bgcnet.sh"

ALL:
	$(MAKE) $(MBGDIR)/$(REFNAME)_001_1_A
	$(MAKE) step_G
	# $(MAKE) step_H

PART1:
	$(MAKE) $(ClustersDatabase)

$(TABLEDIR)/$(REFNAME)_%.gbk:
	mkdir -p `dirname $@`
	python table_1_gen.py `ls $(INPUTDIR)/$(REFNAME)/*cluster$*.gbk` $(TABLEDIR)/$(REFNAME)_$*
	python category_gen.py $(TABLEDIR)/$(REFNAME)_$*
	python table_1_extender.py $(REFNAME) $*
	-rm temp.txt

$(TABLEDIR)/$(REFNAME)_%_table2_1.csv: $(TABLEDIR)/$(REFNAME)_%.gbk
	cd $(TABLEDIR); python $(SRC)/subcluster_gen.py $(REFNAME)_$*

$(ClustersDatabase)/MIBiG:
	mkdir -p $@
	BioCompass download-MIBiG --outputdir $@

$(ClustersDatabase)/CUSTOMDB: $(ClustersDatabase)/MIBiG
	if [ -d $(CUSTOMDB) ]; then \
	ls -R $(CUSTOMDB) | xargs -I file cp $(CUSTOMDB)/file $(ClustersDatabase) ;\
	fi;

$(ClustersDatabase): $(ClustersDatabase)/CUSTOMDB
	mkdir -p $@
	for file in $(CLUSTER_LIST); \
		do BioCompass download-hits --outputdir $@ $$file; \
		done

$(TABLEDIR)/$(REFNAME)_db: $(ClustersDatabase)
	mkdir -p `dirname $@`
	export PATH="$(PATH):$(MULTIGENEBLASTDIR)"; \
	cd `dirname $@`; \
	python $(MAKEDB) `basename $@` \
		$(ClustersDatabase)`ls -R $(ClustersDatabase) | awk -v ORS=' '  '{ print $1 }' | sed 's/,$/\n/'`

$(MBGDIR)/$(REFNAME)_001_1_A: $(TABLE2_1) $(TABLEDIR)/$(REFNAME)_db
	mkdir -p $(MBGDIR)

	cd $(MULTIGENEBLASTDIR); \
	for file in $(GBK_INPUT_LIST); \
	    do n=`echo $$file |  sed -e 's/.*cluster\(.*\)\.gbk/\1/'`; \
	    echo $$n; \
	    nclusters=`ls ${TABLEDIR}/${REFNAME}_$${n}_table2_*.csv  | wc -l`; \
	    echo "nclusters: "$${nclusters}; \
	    for j in $$(seq 1 $${nclusters}); \
	        do echo "j: "$$j; \
	        table2=${TABLEDIR}/${REFNAME}_$${n}_table2_$${j}.csv; \
		while IFS= read -r line; \
		    do case "$$line" in 'BGC'*) continue ;; esac; \
		    genes=`echo $$line | awk '{print $$4}'`; \
		    sub=`echo $$line | awk '{print $$5}'`; \
		    python $(MULTIGENEBLAST) \
		        -db $(OUTPUTDIR)/$(REFNAME)_db \
		        -in ${TABLEDIR}/${REFNAME}_$${n}.gbk \
			-hitspergene 50 -minseqcov 80 -minpercid 50 \
			-genes $${genes} \
			-out $(MBGDIR)/${REFNAME}_$${n}_$${j}_$${sub}; \
	            done < $$table2; \
	        done; \
	    done


step_G:
	mkdir -p $(MBGDIR)

	cd $(MBGDIR); \
	for file in $(GBK_INPUT_LIST); \
	    do n=`echo $$file |  sed -e 's/.*cluster\(.*\)\.gbk/\1/'`; \
	    if [ ! -f $(REFNAME)_edges_all_itineration.txt ]; \
	        then \
		    python $(SRC)/edges_gen.py $(REFNAME)_$${n} 1; \
		    mv $(REFNAME)_$${n}_edges_1.txt $(REFNAME)_edges_all_itineration.txt; \
		    ls $(TABLEDIR)/$(REFNAME)_$${n}_table2_*.csv | cat > itineration.txt; \
		    iti=`cat itineration.txt | wc -l`; \
		    for j in $$(seq 2 $$iti); \
		        do \
	                python $(SRC)/edges_gen.py $(REFNAME)_$${n} $${j}; \
		        cat $(REFNAME)_$${n}_edges_$${j}.txt | \
			    sed 1d >> $(REFNAME)_edges_all_itineration.txt; \
		        rm $(REFNAME)_$${n}_edges_$${j}.txt; \
			done; \
		else \
	            ls $(TABLEDIR)/$(REFNAME)_$${n}_table2_*.csv | cat > itineration.txt; \
		    iti=`cat itineration.txt | wc -l`; \
		    for j in $$(seq 1 $$iti); \
		        do \
			python $(SRC)/edges_gen.py $(REFNAME)_$${n} $${j}; \
			cat $(REFNAME)_$${n}_edges_$${j}.txt | \
			    sed 1d >> $(REFNAME)_edges_all_itineration.txt; \
			rm $(REFNAME)_$${n}_edges_$${j}.txt; \
			done; \
		fi; \
	    done

	rm $(MBGDIR)/itineration.txt

	cd $(MBGDIR); \
	python $(SRC)/keep_best_itineration.py $(REFNAME)

step_H: step_G
	cd $(MBGDIR); \
		python $(SRC)/filter_edges.py $(REFNAME)

	cd $(MBGDIR); \
		python $(SRC)/feature_gen.py $(REFNAME) $(REFNAME)_edges_filtered.txt
	mv $(MBGDIR)/$(REFNAME)_features.txt $(OUTPUTDIR)
	mv $(MBGDIR)/$(REFNAME)_edges_all_itineration.txt $(OUTPUTDIR)
	mv $(MBGDIR)/$(REFNAME)_edges_best_itineration.txt $(OUTPUTDIR)
	mv $(MBGDIR)/$(REFNAME)_edges_filtered.txt $(OUTPUTDIR)

#legacy:
#	./run_bgcnet.sh

clean:
	-rm -r $(TABLEDIR)
	-rm -r $(OUTPUTDIR)
	-rm -r $(ROOT)/merged_results
