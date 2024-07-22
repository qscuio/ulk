target remote :1234

set pagination off
set print pretty
set radix 16

source ../scripts/stack-inspector.py

# rb x64_sys
# disable

# b __switch_to
# disable

# rb _fault[$|_]*
# disable

# rb ^sysvec_ 
# disable

# rb ^exc
# disable

# b common_interrupt
# disable

define __check_cpl
  set $csv = $cs & 0x3
  if $csv == 3
     echo "CPL is 3, stopping execution.\n"
     interrupt
  end
end

define check_cpls
  while 1
    # Continue to the next instruction
    s
    # 2M page
    print ((struct task_struct *)((unsigned long)$rsp & ~0x1fffff))->comm
    # 4K page
    # print ((struct task_struct *)((unsigned long)$rsp & ~0x1fff))->comm 
    # Check the current privilege level
    __check_cpl
  end
end

define check_cpln
  while 1
    # Continue to the next instruction
    n
    # 2M page
    print ((struct task_struct *)((unsigned long)$rsp & ~0x1fffff))->comm
    # 4K page
    # print ((struct task_struct *)((unsigned long)$rsp & ~0x1fff))->comm 
    # Check the current privilege level
    __check_cpl
  end
end

b exc_page_fault
command
bt
continue
end

b handle_page_fault
command
bt
continue
end

b handle_mm_fault
command
bt
continue
end

b __do_fault
command
bt
print *vmf
print *vmf->vma
*print vmf->vma->vm_ops
continue
end

b filemap_fault
command
bt
continue
end

delete 

