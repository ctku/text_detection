#include <stdio.h>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <opencv2/nonfree/nonfree.hpp>
#include <opencv2/nonfree/features2d.hpp>
#include <opencv2/calib3d/calib3d.hpp> // for homography
#include <opencv2/imgproc/imgproc.hpp>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <time.h>

#include "TextDtctGS.h"

using namespace cv;
using namespace std;


//#define MY_DEBUG

#ifdef MY_DEBUG
int main(void)
#else
int main(int argc, char* argv[])
#endif
{	string imgListName;
	string rstImgPath;
	string srcImgPath = "./images/";
	int imgCount = 0;
	bool genReport = 0;
	string reportPath;

#ifdef MY_DEBUG
	//imgListName = "./imageList1.txt";
	//imgListName = "./imageList.txt";
	imgListName = "./imageList_MSRA-train8_50.txt";
	//srcImgPath = "./images/";
	srcImgPath =			"./MSRA-train8_50/";
	rstImgPath = "./results/MSRA-train8_50/";
	genReport = 0;
	reportPath = "./reports/MSRA-train8_50/";
#else
	srcImgPath = argv[1];
	imgListName = argv[2];
	rstImgPath = argv[3];
	if(argc==5)
	{	genReport = 1;
		reportPath = argv[4];
	}
#endif

	ifstream fin(imgListName);

	string imgName;
	while(!fin.eof()) {
		fin >> imgName;
		Mat img = imread(srcImgPath + imgName);
		string reportPathName = reportPath + imgName + ".feat.txt";
		string mserPathName = reportPath + imgName + ".mser.txt";
		imgCount++;
		Mat grayImg, yuvImg, hsvImg, img_kpts, img_ellipse;
		cvtColor(img, grayImg, CV_BGR2GRAY);
		//cvtColor(img, yuvImg, COLOR_BGR2YCrCb);
		//cvtColor(img, hsvImg, CV_RGB2HSV);
		img_kpts = img.clone();
		img_ellipse = img.clone();

		vector<KeyPoint> kpts;
		vector<vector<Point> > contours, newContours;
		vector<ContourAux> contourAuxs, newContourAuxs;
		contourAuxs.clear();
		//Ptr<FeatureDetector> detector;
		//detector = new MSER();
		//detector->detect(grayImg, contours);
		
		int delta=5; int min_area=60; int max_area=img.cols * img.rows / 30;
		double max_variation=0.25; double min_diversity=0.7;
        int max_evolution=200; double area_threshold=1.01;
        double min_margin=0.003; int edge_blur_size=5;
		cout << "max_area: " << max_area << endl;
		MSER(delta, min_area, max_area, max_variation, min_diversity,
          max_evolution, area_threshold, min_margin, edge_blur_size) (grayImg, contours);

		//MSER()(img, contours);
		//MSER()(yuvImg, contours);
		//MSER()(hsvImg, contours);

		//drawKeypoints(img, kpts, img_kpts, Scalar::all(-1), DrawMatchesFlags::DEFAULT);
		cout << endl << imgCount << ". " << imgName << endl;
		cout << "original MSER number : " << contours.size() <<endl;
		
		extractAuxInfo(contours, contourAuxs);
		vector<ContourAux> backupAuxs = contourAuxs;

		////prune MSERs
		//while( pruneContours(contours, contourAuxs, newContours, newContourAuxs) )
		//{	contours = newContours;
		//	contourAuxs = newContourAuxs;
		//	cout << "pruned MSER number : " << newContours.size() <<endl;
		//	newContours.clear();
		//	newContourAuxs.clear();
		//}
		//newContourAuxs.clear();
		//extractAuxInfo(newContours, newContourAuxs);
		
		//newContours = contours;
		//newContourAuxs = contourAuxs;
		newContours.clear();
		newContourAuxs.clear();
		deoverlapContours(contours, contourAuxs, newContours, newContourAuxs);
		//after deoverlap, some aux are missing xCent and yCent, so need to extract aux again
		newContourAuxs.clear();
		extractAuxInfo(newContours, newContourAuxs);
		vector<Feature> features;
		extractFeature(newContours, newContourAuxs, img, features);

		cout << "final MSER number : " << newContours.size() <<endl;
		stringstream ss;
		ss<< newContours.size();
		string mserNumStr = ss.str();

		cout << "image width: " << img.cols << " , height: " << img.rows << endl;

		for( int i = 0 ; i < (int)newContours.size(); i++)
		{	const vector<Point>& r = newContours[i];
			for ( int j = 0; j < (int)r.size(); j++ )
			{
				Point pt = r[j];
				img_kpts.at<Vec3b>(pt) = bcolors[i%9];
				
			}
			
			//cout << "i=" << i << endl;
			//Point2f vertices[4];
			//features[i].rotRect.points(vertices);
			//for (int kk = 0; kk < 4; kk++)
			//	line(img_ellipse, vertices[kk], vertices[(kk+1)%4], Scalar(0,255,0));
			//cout << "angle = " << features[i].angle << endl;
			//cout << "mnmjRatio = " << features[i].mnmjRatio << endl;
			//
			//imshow("ellipsis", img_ellipse);

			//imshow("MSERs", img_kpts);//
			////cout << i+1 << ".  solidity: " << features[i].solidity << endl; 
			////cout << i+1 << ".  strokeW: " << features[i].strokeW << endl; 
			////cout << i+1 << ".  hullArea: " << features[i].hullArea<< endl; 
			////cout << i+1 << ".  hullLength: " << features[i].hullLength << endl; 
			//
			//if ( i >= 23)
			//	waitKey(0);
		}
		imwrite(string(rstImgPath + imgName + ".RGBtoGRAY_mser" + mserNumStr + ".jpg"), img_kpts);
		
		
		
		ofstream outMSER(mserPathName.c_str()); //save pixels in MSERs
		for(int i=0; i<newContours.size(); i++) 
		{	const vector<Point>& r = newContours[i];
			outMSER << "MSER " << r.size() << endl;
			for ( int j = 0; j < (int)r.size(); j++ )
			{	outMSER << r[j].x << " ";
			}
			outMSER << endl;
			for ( int j = 0; j < (int)r.size(); j++ )
			{	outMSER << r[j].y << " ";
			}
			outMSER << endl;
		}
		outMSER.close();

		ofstream outFeat(reportPathName.c_str()); //report to save MSER centers and features
		for(int i=0; i<newContourAuxs.size(); i++) 
		{	outFeat << newContourAuxs[i].xMassCent << " " << newContourAuxs[i].yMassCent << " " << features[i].size << " "
			<< features[i].R << " " << features[i].G << " " << features[i].B << " "
			<< newContourAuxs[i].xMin << " " << newContourAuxs[i].xMax << " "
			<< newContourAuxs[i].yMin << " " << newContourAuxs[i].yMax << " " 
			<< features[i].solidity << " " 
			<< features[i].strokeW << " " 
			<< features[i].angle << " "
			<< features[i].mnmjRatio
			<< endl;
		}
		outFeat.close();
		


		//drawContours(img_kpts, contours, -1, Scalar(0,255,255)); //very messy
		
		//vector<int> intensity;
		//intensity.reserve(newContours.size());
		//double tempIntensity = 0; 
		//for( int i = 0 ; i < (int)newContours.size(); i++)
		//{
		//	const vector<Point>& r = newContours[i];
		//	/*for( int k = 0; k < 10; k++ )
		//	{	Point tempPoint(i,k);
		//		r.push_back( tempPoint);
		//	}*/
		//	tempIntensity = 0;
		//	for ( int j = 0; j < (int)r.size(); j++ )
		//	{
		//		Point pt = r[j];
		//		//img_kpts.at<Vec3b>(pt) = bcolors[i%9];
		//		tempIntensity += double( grayImg.at<UCHAR>(pt) );
		//	}
		//	tempIntensity /= r.size();
		//	intensity.push_back( int(tempIntensity) );
		//	
		//	/*Point corner1(newContourAuxs[i].xMin, newContourAuxs[i].yMin);
		//	Point corner2(newContourAuxs[i].xMax, newContourAuxs[i].yMin);
		//	Point corner3(newContourAuxs[i].xMax, newContourAuxs[i].yMax);
		//	Point corner4(newContourAuxs[i].xMin, newContourAuxs[i].yMax);
		//	line(img_kpts, corner1, corner2, Scalar(255,255,255), 1 );
		//	line(img_kpts, corner2, corner3, Scalar(255,255,255), 1 );
		//	line(img_kpts, corner3, corner4, Scalar(255,255,255), 1 );
		//	line(img_kpts, corner4, corner1, Scalar(255,255,255), 1 );*/
		//	
		//	
		//	// find ellipse (it seems cvfitellipse2 have error or sth?)
		//	//RotatedRect box = fitEllipse( r );
		//	//box.angle=(float)CV_PI/2-box.angle;
		//	//ellipse( ellipses, box, Scalar(196,255,255), 2 );
		//	
		//	//imshow("MSERs", img_kpts);
		//	//waitKey(0);
		//}

		//cout << "intensity decompose..." << endl;
		//vector<vector<int> > intenInd; //stores indices of msers for each intensity, typically from 0 to 255
		//int layerRange = 20;
		//int layerOverlap = 5;
		//int upperBound = 255;
		////layerDecompose(intensity, layerInd, layerRange, layerOverlap);
		//int step = layerRange - layerOverlap;
		//int numLayers = 1 + int( ceil( double(upperBound + 1 - layerRange) / double(step)) );
		//intensityDecompose(intensity, intenInd, upperBound);

		//cout << numLayers <<  " layers to be extracted ..." << endl;
		//A layer is comprised of those MSERs that have certain range of intensities.  
		//Divide 0-255 into multiple partially overlapping layers and extract MSERs for each layer.
		//vector<vector<int> > layerInds; //indices of msers for each layer
		//vector<int> layerInd; //indices of mser for one layer
		//for( int i = 0; i < numLayers; i++)
		//{	layerInd.clear();
		//	layerExtract(intenInd, layerInd, i, layerRange, layerOverlap, upperBound);
		//	layerInds.push_back(layerInd);
		//}
		
		//cout << "draw layers ..." << endl;
		//draw different layers
		/*for( int i = 0; i < numLayers; i++)
		{	layerInd = layerInds[i];
			Mat layerImg(img_kpts.rows, img_kpts.cols, CV_8UC3);
			for( int j = 0; j < layerInd.size(); j++)
			{	int ind = layerInd[j];
				const vector<Point>& r = newContours[ind];
				for ( int k = 0; k < (int)r.size(); k++ )
				{	const Point& pt = r[k];
					layerImg.at<Vec3b>(pt) = img.at<Vec3b>(pt);
				}
			}
			stringstream ss;
			ss << i;
			string layerLabel = ss.str();
			imwrite( rstImgPath + imgName + "." + layerLabel + ".jpg", layerImg);
		}*/


		
		
		
	

		

		//int mserWid, mserHei;
		//int xCent, yCent, xCentTemp, yCentTemp;
		//int patWid, patHei, patXmin, patXmax, patYmin, patYmax, xHalfExt, yHalfExt;
		//int patHorRatio = 5;
		//int patVerRatio = 3;
		//double mserSim;

		//for( int i = 0; i < newContours.size(); i++) 
		//{	xCent = newContourAuxs[i].xMassCent;
		//	yCent = newContourAuxs[i].yMassCent;
		//	mserWid = newContourAuxs[i].xMax - newContourAuxs[i].xMin + 1;
		//	mserHei = newContourAuxs[i].yMax - newContourAuxs[i].yMin + 1;
		//	patWid = patHorRatio * mserWid;
		//	patHei = patVerRatio * mserHei;
		//	xHalfExt = (patHorRatio-1)/2 * mserWid;
		//	yHalfExt = (patVerRatio-1)/2 * mserHei;
		//	patXmin = newContourAuxs[i].xMin - xHalfExt;
		//	patXmax = newContourAuxs[i].xMax + xHalfExt;
		//	patYmin = newContourAuxs[i].yMin - yHalfExt;
		//	patYmax = newContourAuxs[i].yMax + yHalfExt;
		//	checkBoundary(patXmin, patXmax, patYmin, patYmax, img.cols, img.rows);
		//	Mat patch(Size(patXmax-patXmin+1, patYmax-patYmin+1), CV_64FC1);
		//	drawOnPatch(patch, patXmin, patXmax, patYmin, patYmax, newContours[i], 1);

		//	for( int j = 0 ; j < newContours.size(); j++ )
		//	{	xCentTemp = newContourAuxs[j].xMassCent;
		//		yCentTemp = newContourAuxs[j].yMassCent;
		//		if( !isOutside(patXmin, patXmax, patYmin, patYmax, newContourAuxs[j] ) )
		//		{	//compute similarity between current mser and center mser
		//			mserSim = mserSimilarity(features[i], features[j]);
		//			//draw on the patch
		//			drawOnPatch(patch, patXmin, patXmax, patYmin, patYmax, newContours[j], mserSim);
		//			//scale the patch to standard size

		//		}

		//	}
		//}



	}
}

