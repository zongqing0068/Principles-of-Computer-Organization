#include <stdio.h>
#include <stdlib.h>


int main(void) {
	int stuID = 13;
	int mulNum1 = stuID;	//mulNum1Ϊ������
	int mulNum2 = stuID;	//mulNum2Ϊ����
	int ans = 0;
	int count;
	mulNum1 <<= 8;
	for(count=0; count<8; count++){
		if(mulNum2 & 1){
			ans += mulNum1;
		}
		mulNum2 >>= 1;
		ans >>= 1;
	}
	printf("%d\n", ans);	//����ѧ�ŵ�ƽ�� 
	
	mulNum1 = ans<<8; 
	mulNum2 = stuID;
	for(count=0; count<8; count++){
		if(mulNum2 & 1){
			ans += mulNum1;
		}
		mulNum2 >>= 1;
		ans >>= 1;
	}
	printf("%d\n", ans);	//����ѧ�ŵ����� 
	return 0;
}

