
#include "../include/system.h"
#include "../include/imfeat.h"
#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <opencv2/ml/ml.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <opencv2/nonfree/nonfree.hpp>
#include <opencv2/nonfree/features2d.hpp>
#include <opencv2/calib3d/calib3d.hpp> // for homography
#include <opencv2/imgproc/imgproc.hpp>
using namespace cv;
using namespace std;

extern int get_ERs(
			 u8 *img_data,
			 int img_rows,
			 int img_cols,
			 int *out,
			 int *pxl,
			 int reverse );

extern int main_sample(void);

int main(void)
{
	main_sample();

#if 0
	// src 1
	int img_cols = 4;
	int img_rows = 4;
	u8* img_data = (u8*)malloc(img_cols*img_rows*sizeof(u8));
	u8* img_ptr = img_data;
	img_ptr[0] =  1; img_ptr[1] =  2; img_ptr[2] =  1; img_ptr[3] =  3;
	img_ptr[4] =  4; img_ptr[5] =  1; img_ptr[6] =  5; img_ptr[7] =  1;
	img_ptr[8] =  1; img_ptr[9] =  6; img_ptr[10] = 1; img_ptr[11] = 7;
	img_ptr[12] = 8; img_ptr[13] = 1; img_ptr[14] = 9; img_ptr[15] = 1;

	int* out = (int*)malloc( (img_rows*img_cols*3)*sizeof(int) );
	int* pxl = (int*)malloc( (img_rows*img_cols)*sizeof(int) );
	int no_ER = get_ERs(img_data, img_rows, img_cols, out, pxl, 2);

	free(img_data);
	printf("this test is good\n");
	char ch;
	scanf("%c", &ch);

	free(out);
	free(pxl);
#endif
#if 0
	string path_prefix = "../../../";
	string path_filelist = path_prefix + "../../../Dataset/MSRA-TD500/test/parsed_filenames.txt";
	ifstream fin(path_filelist);
	int img_no;

	fin >> img_no;
	for (int i=1; i<=img_no; i++)
	{
		// get image
		char path_img[128];
		fin >> path_img;
		Mat img = imread(path_prefix + path_img, CV_LOAD_IMAGE_GRAYSCALE);

		// calculate ER
		int* out = (int*)malloc((img.rows*img.cols*3)*sizeof(int));
		int* pxl = (int*)malloc((img.rows*img.cols)*sizeof(int));
		int ER_no = get_ERs(img.data, img.rows, img.cols, out, pxl, 0);

		// Boost parameters
		CvBoostParams bstparams;
		bstparams.boost_type = CvBoost::REAL;
		bstparams.weak_count = 100;
		bstparams.weight_trim_rate = 0.95;
		bstparams.split_criteria = CvBoost::DEFAULT;

		// Run the training
		CvBoost *boost = new CvBoost;
		boost.train(featureVectorSamples, 
					CV_ROW_SAMPLE, 
					classLabelResponses, 
					0, 0, var_type, 
					0, bstparams);
#endif

#if 0
	char input[128];
	FILE *fin;
	fin = fopen(, "r");
	fscanf(fin, "%s", input);
	int img_no = atoi(input);

	char path_prefix[10] = "../../../";
	for (int i=1; i<=img_no; i++)
	{
		fscanf(fin, "%s", input);
		IplImage *img=cvLoadImage(strcat(path_prefix, input));

		cvtColor(img, grayImg, CV_BGR2GRAY);
		int a = 0;

	}

	if (file) {
		while (fscanf(file, "%s", str)!=EOF)
			printf("%s",str);
		fclose(file);
	}

	IplImage *img=cvLoadImage("../../../../../../Dataset/MSRA-TD500/test/IMG_0059.JPG");
	cvNamedWindow("a");
	cvShowImage("a", img);
	cvWaitKey(0);
	//CvMat img = imread("aPICT0034.JPG", CV_LOAD_IMAGE_GRAYSCALE);

	//int* out = (int*)malloc( (img.rows*img.cols*3)*sizeof(int) );
	//int* pxl = (int*)malloc( (img.rows*img.cols)*sizeof(int) );
	//get_ERs(&img, out, pxl, 0);

	//struct aa a;
#endif
	//fclose(fin);

	return 0;
}