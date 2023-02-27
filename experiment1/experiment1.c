#include <stdio.h>
#include <stdlib.h>


int main(void) {
	int stuID = 13;
	int mulNum1 = stuID;	//mulNum1为被乘数
	int mulNum2 = stuID;	//mulNum2为乘数
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
	printf("%d\n", ans);	//计算学号的平方 
	
	mulNum1 = ans<<8; 
	mulNum2 = stuID;
	for(count=0; count<8; count++){
		if(mulNum2 & 1){
			ans += mulNum1;
		}
		mulNum2 >>= 1;
		ans >>= 1;
	}
	printf("%d\n", ans);	//计算学号的立方 
	return 0;
}

