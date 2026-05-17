/*
 * image_pool.cpp
 *
 *  Created on: 2017. 7. 12.
 *      Author: woobes
 */

// ======================================================================
// 풀링 계층 (Pooling Layers) - *현재 비활성화(주석 처리)됨*
// 2x2 윈도우 내에서 최댓값을 찾는 Max Pooling의 C++ 기반 하드웨어 구현체입니다.
// 베이스라인 코드는 풀링을 별도 함수로 분리했으나, 
// 우리가 새로 만들 cnn_alu.cpp에서는 속도를 위해 합성곱 직후에 풀링을 강결합(Tightly-coupled)하여 처리할 예정입니다.
// ======================================================================
/*
void MAXPOOL_1(float OutputBuffer[image_Batch][6][28*28], float dst[image_Batch*6*14*14]){
	#pragma HLS INLINE
	for(int batch=0;batch<image_Batch;batch++){
		for(int depth=0;depth<POOL_1_TYPE;depth++){
			for(int row=0;row<POOL_1_OUTPUT_WH;row++){
				for(int col=0;col<POOL_1_OUTPUT_WH;col++){
					#pragma HLS pipeline
					float max1, max2, max;
					float a00, a01, a10, a11;
					int rr = row<<1;
					int cc = col<<1;
					a00 = OutputBuffer[batch][depth][rr*28+cc];
					a01 = OutputBuffer[batch][depth][rr*28+cc+1];
					a10 = OutputBuffer[batch][depth][(rr+1)*28+cc];
					a11 = OutputBuffer[batch][depth][(rr+1)*28+cc+1];
					max1 = a00 > a01 ? a00 : a01;
					max2 = a10 > a11 ? a10 : a11;
					max  = max1 > max2 ? max1 : max2;

					/*
					for(int row_w=0;row_w<2;row_w++){
						for(int col_w=0;col_w<2;col_w++){
							if(src[batch*POOL_1_TYPE*POOL_1_INPUT_SIZE + depth*POOL_1_INPUT_SIZE +
								(2*row+row_w)*POOL_1_INPUT_WH + col*2+col_w]>max){
								max = src[batch*POOL_1_TYPE*POOL_1_INPUT_SIZE + depth*POOL_1_INPUT_SIZE +
											(2*row+row_w)*POOL_1_INPUT_WH + col*2+col_w];
							}
						}
					}
					dst[batch*POOL_1_TYPE*POOL_1_OUTPUT_SIZE + depth*POOL_1_OUTPUT_SIZE + row*POOL_1_OUTPUT_WH + col] = _tanh(max);
				}
			}
		}
	}
}
void MAXPOOL_2(float OutputBuffer[image_Batch][16][10*10], float dst[image_Batch*16*5*5]){
	#pragma HLS INLINE
	for(int batch=0;batch<image_Batch;batch++){
		for(int depth=0;depth<POOL_2_TYPE;depth++){
			for(int row=0;row<POOL_2_OUTPUT_WH;row++){
				for(int col=0;col<POOL_2_OUTPUT_WH;col++){
					#pragma HLS pipeline

					float max1, max2, max;
					float a00, a01, a10, a11;
					int rr = row<<1;
					int cc = col<<1;
					a00 = OutputBuffer[batch][depth][rr*10+cc];
					a01 = OutputBuffer[batch][depth][rr*10+cc+1];
					a10 = OutputBuffer[batch][depth][(rr+1)*10+cc];
					a11 = OutputBuffer[batch][depth][(rr+1)*10+cc+1];
					max1 = a00 > a01 ? a00 : a01;
					max2 = a10 > a11 ? a10 : a11;
					max  = max1 > max2 ? max1 : max2;

					/*
					for(int row_w=0;row_w<2;row_w++){
						for(int col_w=0;col_w<2;col_w++){
							if(src[batch*POOL_1_TYPE*POOL_1_INPUT_SIZE + depth*POOL_1_INPUT_SIZE +
								(2*row+row_w)*POOL_1_INPUT_WH + col*2+col_w]>max){
								max = src[batch*POOL_1_TYPE*POOL_1_INPUT_SIZE + depth*POOL_1_INPUT_SIZE +
											(2*row+row_w)*POOL_1_INPUT_WH + col*2+col_w];
							}
						}
					}
					dst[batch*POOL_2_TYPE*POOL_2_OUTPUT_SIZE + depth*POOL_2_OUTPUT_SIZE + row*POOL_2_OUTPUT_WH + col] = _tanh(max);
					/*float max=-FLT_MAX;
					for(int row_w=0;row_w<2;row_w++){
						for(int col_w=0;col_w<2;col_w++){
							if(src[batch*POOL_2_TYPE*POOL_2_INPUT_SIZE + depth*POOL_2_INPUT_SIZE +
								(2*row+row_w)*POOL_2_INPUT_WH + col*2+col_w]>max){
								max = src[batch*POOL_2_TYPE*POOL_2_INPUT_SIZE + depth*POOL_2_INPUT_SIZE +
											(2*row+row_w)*POOL_2_INPUT_WH + col*2+col_w];
							}
						}
					}
					dst[batch*POOL_2_TYPE*POOL_2_OUTPUT_SIZE + depth*POOL_2_OUTPUT_SIZE + row*POOL_2_OUTPUT_WH + col] = max;
				}
			}
		}
	}
}
*/
