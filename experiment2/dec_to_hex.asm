.data
	number: .word 200110513

.text

start:
	lui t0, 0x00002
	lw a2, 0x0(t0)		# 将学号存入a2寄存器中
	addi a3, x0, 0x0	# 将a3寄存器置零，用于存储最终数据
	addi a4, x0, 0x10	# 运用直接法转换十六进制，将立即数16存入a4寄存器中
	addi a5, x0, 0x0	# 将a5寄存器置0，表示每次循环存数的左移位数
loop:
	beq a2, x0, done	# 若余数为0，则跳出循环
	jal ra, func		# 进入函数
	jal x0, loop		# 继续循环
	
# 子函数，用于计算十六进制的每一位并加到a3寄存器中
func:
	rem t1, a2, a4		# 求出十六进制表示的当前位上的数
	sll t1, t1, a5		# 将该数左移相应的位数
	add a3, a3, t1		# 将该位上的数经过左移后加到a3寄存器中保存的结果的相应位上
	div a2, a2, a4		# 求出剩余待转换的十进制数
	addi a5, a5, 4		# 每次左移的位数都要加4
	jalr x0, 0x0(ra)	# 返回调用子函数的位置
done:
