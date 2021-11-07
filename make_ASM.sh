cd .
#!/bin/bash
objdump -S -D -l -g --disassembler-options=intel -M --x86-64 ./code/shared/cl_main.o > cl_main.asm

read -p "Press any key to continue." x     
