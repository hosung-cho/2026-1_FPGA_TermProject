#ifndef SRC_MNIST_DATA_H_
#define SRC_MNIST_DATA_H_
#include <iostream>
#include <fstream>
#include "../lenet5/common.h"
#define TRUE 1
#define FALSE 0

using namespace std;

// MNIST 원본 픽셀은 unsigned 8-bit, 즉 0~255 범위입니다.
// CNN_ALU는 signed INT8 activation을 받으므로, 기존 float baseline의 입력 범위인
// -1.0~1.0에 맞춰 대략 -127~127 범위로 양자화합니다.
//
// 변환 의미:
//   pixel 0   -> -127  (검은 배경 및 padding)
//   pixel 128 -> 약 0
//   pixel 255 -> 127   (가장 밝은 획)
//
// 수식으로는 round((pixel / 255.0) * 254.0 - 127.0)와 같습니다.
// 부동소수점 roundf 없이 정수 연산으로 구현해서 RV32I 펌웨어로 옮기기 쉽도록 했습니다.
static signed char QuantizeMNISTPixelToInt8(unsigned char pixel) {
	int q = ((int)pixel * 254 + 127) / 255 - 127;

	if (q < -128) q = -128;
	if (q > 127) q = 127;

	return (signed char)q;
}

int ReverseInt(int i) {
	
	
	unsigned char ch1, ch2, ch3, ch4;
	ch1 = i & 255;
	ch2 = (i >> 8) & 255;
	ch3 = (i >> 16) & 255;
	ch4 = (i >> 24) & 255;

	return((int)ch1 << 24) + ((int)ch2 << 16) + ((int)ch3 << 8) + ch4;

}


// Read MNIST Data to padded array
void READ_MNIST_DATA(string filename, float* arr, float scale_min, float scale_max, int image_num=image_Move) {
	ifstream file(filename.c_str(), ios::binary);
	cout << "Read MNIST DATA..."<< endl;
	if (file.is_open())
	{
		
		int magic_number = 0;
		int number_of_images = 0;
		int n_rows = 0;
		int n_cols = 0;
		file.read((char*)&magic_number, sizeof(magic_number));
		magic_number = ReverseInt(magic_number);
		file.read((char*)&number_of_images, sizeof(number_of_images));
		number_of_images = ReverseInt(number_of_images);
		file.read((char*)&n_rows, sizeof(n_rows));
		n_rows = ReverseInt(n_rows);
		file.read((char*)&n_cols, sizeof(n_cols));
		n_cols = ReverseInt(n_cols);
		int batch = number_of_images > image_num ? image_num : number_of_images;
		for (int i = 0; i<batch; ++i)
		{
			//for (int r = 0; r<n_rows; ++r)
			for (int r = 0; r<32; ++r)
			{
				//for (int c = 0; c<n_cols; ++c)
				for(int c=0;c<32;++c)
				{

					float _temp;
					if(c<2 || r<2 || c>=30|| r>=30)
						_temp = scale_min;
					else{
						unsigned char temp = 0;
						file.read((char*)&temp, sizeof(temp));
						_temp = ((float)temp / 255.0 )*(scale_max - scale_min) + scale_min;
					}

					arr[i*1024 + r*32 + c] = _temp;
				}
			}
		}
		cout << "MNIST DATA is loaded" << endl;

	}
	else {
		cout << "Failed to read MNIST DATA" << endl;
	}


}

// Read MNIST Data to signed INT8 padded array
//
// 기존 READ_MNIST_DATA()는 float 배열에 -1.0~1.0 값으로 저장합니다.
// 이 함수는 CNN_ALU용으로 같은 32x32 padding 구조를 유지하되, 각 픽셀을 signed INT8로
// 저장합니다. 출력 배열 크기는 image_num * 1024 이상이어야 합니다.
//
// 메모리 배치:
//   arr[image_index * 1024 + row * 32 + col]
//
// padding 정책:
//   원본 MNIST는 28x28이고, LeNet 입력은 32x32입니다.
//   위/아래/좌/우 2픽셀 padding을 추가하며, padding 값은 pixel 0과 같은 -127입니다.
void READ_MNIST_DATA_INT8(string filename, signed char* arr, int image_num=image_Move) {
	ifstream file(filename.c_str(), ios::binary);
	cout << "Read MNIST DATA as INT8..."<< endl;
	if (file.is_open())
	{
		int magic_number = 0;
		int number_of_images = 0;
		int n_rows = 0;
		int n_cols = 0;
		file.read((char*)&magic_number, sizeof(magic_number));
		magic_number = ReverseInt(magic_number);
		file.read((char*)&number_of_images, sizeof(number_of_images));
		number_of_images = ReverseInt(number_of_images);
		file.read((char*)&n_rows, sizeof(n_rows));
		n_rows = ReverseInt(n_rows);
		file.read((char*)&n_cols, sizeof(n_cols));
		n_cols = ReverseInt(n_cols);
		int batch = number_of_images > image_num ? image_num : number_of_images;
		signed char pad_value = QuantizeMNISTPixelToInt8(0);

		for (int i = 0; i<batch; ++i)
		{
			for (int r = 0; r<32; ++r)
			{
				for(int c=0;c<32;++c)
				{
					signed char q_value;
					if(c<2 || r<2 || c>=30|| r>=30) {
						q_value = pad_value;
					}
					else {
						unsigned char temp = 0;
						file.read((char*)&temp, sizeof(temp));
						q_value = QuantizeMNISTPixelToInt8(temp);
					}

					arr[i*1024 + r*32 + c] = q_value;
				}
			}
		}
		cout << "MNIST INT8 DATA is loaded" << endl;

	}
	else {
		cout << "Failed to read MNIST DATA" << endl;
	}
}

template <typename T>
void READ_MNIST_LABEL(string filename, T* label, int image_num=10000, int one_hot = TRUE)
{
	ifstream file(filename.c_str(), ios::binary);
	cout << "Read MNIST Label..." << endl;
	if (file.is_open())
	{
		int magic_number = 0;
		int number_of_images = 0;

		file.read((char*)&magic_number, sizeof(magic_number));
		magic_number = ReverseInt(magic_number);
		file.read((char*)&number_of_images, sizeof(number_of_images));
		number_of_images = ReverseInt(number_of_images);
		int batch = number_of_images > image_num ? image_num : number_of_images;
		for (int i = 0; i<batch; ++i)
		{
			unsigned char temp = 0;
			file.read((char*)&temp, sizeof(temp));
			if (one_hot) 
			{
				label[i * 10 + (int)temp] = 1;
			}
			else
			{
				label[i] = (T)temp;
			}
			
		}
		cout << "MNIST Label is loaded" << endl;
	}
	else
	{
		cout << "Failed to read MNIST Label" << endl;
	}
//	file.close();
}

void preprocessTestImage(float* input_layer, unsigned char* test_img, float scale_min, float scale_max){
	//for (int r = 0; r<n_rows; ++r)
	for (int r = 0; r<32; ++r)
	{
		//for (int c = 0; c<n_cols; ++c)
		for(int c=0;c<32;++c)
		{
			float _temp;

			unsigned char temp = test_img[r*32+c+1];

			_temp = ((float)temp / 255.0 )*(scale_max - scale_min) + scale_min;

			input_layer[r*32 + c] = _temp;
		}
	}
}

// UDP/GUI 등에서 받은 32x32 raw image buffer를 CNN_ALU용 signed INT8 입력으로 변환합니다.
// 기존 preprocessTestImage()는 float 출력용이고, 이 함수는 INT8 출력용입니다.
// test_img[0]은 프로토콜 헤더로 쓰이므로 기존 코드와 동일하게 test_img[r*32+c+1]부터 읽습니다.
void preprocessTestImage_INT8(signed char* input_layer, unsigned char* test_img){
	for (int r = 0; r<32; ++r)
	{
		for(int c=0;c<32;++c)
		{
			unsigned char temp = test_img[r*32+c+1];
			input_layer[r*32 + c] = QuantizeMNISTPixelToInt8(temp);
		}
	}
}
#endif
