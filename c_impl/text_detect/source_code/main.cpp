
#include "text_detect.h"
#include "tree.hh"
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


int main(void)
{
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



#if 0
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
	}
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