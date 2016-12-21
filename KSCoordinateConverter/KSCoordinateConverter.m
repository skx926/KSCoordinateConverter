//
//  KSGeometry.m
//  KSGeometry
//
//  Created by Kyle Sun on 19/12/2016.
//  Copyright © 2016 Kyle Sun. All rights reserved.
//

#import "KSCoordinateConverter.h"
#include <math.h>

const double x_pi = 3.14159265358979324 * 3000.0 / 180.0;

void bd_encrypt(double gg_lat, double gg_lon, double *bd_lat, double *bd_lon)
{
    double x = gg_lon, y = gg_lat;
    double z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) + 0.000003 * cos(x * x_pi);
    *bd_lon = z * cos(theta) + 0.0065;
    *bd_lat = z * sin(theta) + 0.006;
}

void bd_decrypt(double bd_lat, double bd_lon, double *gg_lat, double *gg_lon)
{
    double x = bd_lon - 0.0065, y = bd_lat - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) - 0.000003 * cos(x * x_pi);
    *gg_lon = z * cos(theta);
    *gg_lat = z * sin(theta);
}

@implementation KSCoordinateConverter

+ (CLLocationCoordinate2D)bdCoordinateFromGPSCoordinate:(CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D marsCoordinate = [self marsCoordinateFromBDCoordinate:coordinate];
	return [self bdCoordinateFromMarsCoordinate:marsCoordinate];
}

+ (CLLocationCoordinate2D)gpsCoordinateFromBDCoordinate:(CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D marsCoordinate = [self marsCoordinateFromBDCoordinate:coordinate];
    return [self gpsCoordinateFromMarsCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
}

+ (CLLocationCoordinate2D)gpsCoordinateFromMarsCoordinate:(CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D marsCoordinate = [self marsCoordinateFromGPSCoordinate:coordinate];
    double latitude = marsCoordinate.latitude - coordinate.latitude;
    double longitude = marsCoordinate.longitude - coordinate.longitude;
    latitude = coordinate.latitude - latitude;
    longitude = coordinate.longitude - longitude;

    return CLLocationCoordinate2DMake(latitude, longitude);
}

+ (CLLocationCoordinate2D)marsCoordinateFromGPSCoordinate:(CLLocationCoordinate2D)coordinate {

    const double a = 6378245.0;
    const double ee = 0.00669342162296594323;

    if ([self outOfChina:coordinate])  {
        return coordinate;
    }

    double dLat = [self transformLatitudeWithX:coordinate.longitude - 105.0 andY:coordinate.latitude - 35.0];
    double dLon = [self transformLongitudeWithX:coordinate.longitude - 105.0 andY:coordinate.latitude - 35.0];
    double radLat = coordinate.latitude / 180.0 * M_PI;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * M_PI);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * M_PI);
    coordinate.latitude = coordinate.latitude + dLat;
    coordinate.longitude = coordinate.longitude + dLon;

    return coordinate;
}

+ (CLLocationCoordinate2D)bdCoordinateFromMarsCoordinate:(CLLocationCoordinate2D)coordinate {
	double latitude, longitude;
    bd_encrypt(coordinate.latitude, coordinate.longitude, &latitude, &longitude);
    return CLLocationCoordinate2DMake(latitude, longitude);
}

+ (CLLocationCoordinate2D)marsCoordinateFromBDCoordinate:(CLLocationCoordinate2D)coordinate {
	double latitude, longitude;
    bd_decrypt(coordinate.latitude, coordinate.longitude, &latitude, &longitude);
	return CLLocationCoordinate2DMake(latitude, longitude);
}

+ (BOOL)outOfChina:(CLLocationCoordinate2D)coordinate{
    if (coordinate.longitude < 72.004 || coordinate.longitude > 137.8347)
        return YES;
    if (coordinate.latitude < 0.8293 || coordinate.latitude > 55.8271)
        return YES;
    return NO;
}

+ (double)transformLatitudeWithX:(double)x andY:(double)y {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0;
    return ret;
}

+ (double)transformLongitudeWithX:(double)x andY:(double)y {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0;
    return ret;
}

@end
