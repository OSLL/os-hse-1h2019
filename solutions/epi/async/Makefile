PIPE = /home/vlad/au/arch/qwe/os-hse-1h2019/solutions/epi/pipes/pp


ex: pipe.c
	gcc pipe.c -o ex

write: ex
	./ex w $(PIPE)
read: ex
	./ex r $(PIPE)
pp1:
	rm -f pp1
	mkfifo pp1
pp2:
	rm -f pp2
	mkfifo pp2

c1: ex
	./ex ./pp1 ./pp2
c2: ex
	./ex ./pp2 ./pp1

.PHONY: pp1 pp2 c1 c2
