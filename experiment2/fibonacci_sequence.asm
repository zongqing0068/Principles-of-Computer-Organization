.data
	number: .word 20
	
.text

start:
	lui t0, 0x00002
	ld a2, 0x0(t0)		# 将参数n=20存入a2寄存器中
	addi t3, x0, 2		# 设置t3的初值为2
	jal ra, func		# 调用func函数计算fibonacci
	jal x0, done		# 退出程序
	
# 子函数用来计算fibonacci
func:
	addi sp, sp, -16	# 将返回地址和n保存到栈中
	sd ra, 8(sp)
	sd a2, 0(sp)
	addi t0, a2, -1	# t0 = n-1
	addi t1, x0, 1		# 设置t1的初值为1，即func(2)-func(1)=1
	bge t0, t3, L1		# 若t0大于2（即n大于等于3），则跳转到L1
	addi a3, x0, 1		# 当t0小于2（即n小于等于2）时，返回值为1。若n=1，则在后续循环中a3的值不会再改变；若n=2，则再后续循环中a3的值还会加1
	addi sp, sp, 16	# 出栈，此处不需要恢复原值
	jalr x0, 0(ra)		# 返回

L1:
	addi a2, a2, -1	# n = n-1
	jal ra, func		# 调用func(n-1)
	add t2, t1, x0		# 将t1中存的func(n-2)转存到t2中
	addi t1, a3, 0		# 将func(n-1)的结果存到t1中
	ld ra, 8(sp)		# 恢复调用者的返回地址
	addi sp, sp, 16	# 出栈
	add a3, t2, t1		# 结果a3 = t2 * t1，其中t2 = func(n-2)，t1 = (n-1)
	jalr x0, 0(ra)		# 返回
	
done:
	