#include "activation.h"
// ======================================================================
// 활성화 함수 모듈 (Activation Functions) - *현재 비활성화(주석 처리)됨*
// 베이스라인 제작자가 초기에 Tanh와 ReLU를 독립적인 파일로 분리하려고 시도했던 흔적입니다.
// 현재는 이 로직들이 모두 image_convolution.cpp 내부 상단에 통합되어 사용되고 있습니다.
// ======================================================================
/*
float _tanh(float x){
#pragma HLS INLINE
//#pragma HLS pipeline
	float exp2x = expf(2*x)+1;
	return (exp2x-2)/(exp2x);
}

float relu(float x){
#pragma HLS inline
	return x>0 ? x : 0;
}
*/
