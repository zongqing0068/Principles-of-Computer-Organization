.data
	number: .word 20
	
.text

start:
	lui t0, 0x00002
	ld a2, 0x0(t0)		# ������n=20����a2�Ĵ�����
	addi t3, x0, 2		# ����t3�ĳ�ֵΪ2
	jal ra, func		# ����func��������fibonacci
	jal x0, done		# �˳�����
	
# �Ӻ�����������fibonacci
func:
	addi sp, sp, -16	# �����ص�ַ��n���浽ջ��
	sd ra, 8(sp)
	sd a2, 0(sp)
	addi t0, a2, -1	# t0 = n-1
	addi t1, x0, 1		# ����t1�ĳ�ֵΪ1����func(2)-func(1)=1
	bge t0, t3, L1		# ��t0����2����n���ڵ���3��������ת��L1
	addi a3, x0, 1		# ��t0С��2����nС�ڵ���2��ʱ������ֵΪ1����n=1�����ں���ѭ����a3��ֵ�����ٸı䣻��n=2�����ٺ���ѭ����a3��ֵ�����1
	addi sp, sp, 16	# ��ջ���˴�����Ҫ�ָ�ԭֵ
	jalr x0, 0(ra)		# ����

L1:
	addi a2, a2, -1	# n = n-1
	jal ra, func		# ����func(n-1)
	add t2, t1, x0		# ��t1�д��func(n-2)ת�浽t2��
	addi t1, a3, 0		# ��func(n-1)�Ľ���浽t1��
	ld ra, 8(sp)		# �ָ������ߵķ��ص�ַ
	addi sp, sp, 16	# ��ջ
	add a3, t2, t1		# ���a3 = t2 * t1������t2 = func(n-2)��t1 = (n-1)
	jalr x0, 0(ra)		# ����
	
done:
	