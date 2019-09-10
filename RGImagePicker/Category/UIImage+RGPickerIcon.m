//
//  UIImage+RGPickerIcon.m
//  CampTalk
//
//  Created by renge on 2019/9/1.
//  Copyright © 2019 yuru. All rights reserved.
//

#import "UIImage+RGPickerIcon.h"

@implementation UIImage(RGPickerIcon)

+ (UIImage *)rg_sendImage {
    
    CGSize size = CGSizeMake(25, 25);
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    
    //// Color Declarations
    UIColor* fillColor2 = [UIColor colorWithRed: 0.071 green: 0.588 blue: 0.859 alpha: 1];
    
    //// fasong-3.svg Group
    {
        //// Bezier Drawing
        UIBezierPath* bezierPath = UIBezierPath.bezierPath;
        [bezierPath moveToPoint: CGPointMake(16.6, 23.41)];
        [bezierPath addCurveToPoint: CGPointMake(14.52, 22.42) controlPoint1: CGPointMake(15.89, 23.41) controlPoint2: CGPointMake(15.17, 23.07)];
        [bezierPath addLineToPoint: CGPointMake(2.6, 10.49)];
        [bezierPath addCurveToPoint: CGPointMake(1.67, 7.87) controlPoint1: CGPointMake(1.77, 9.67) controlPoint2: CGPointMake(1.44, 8.74)];
        [bezierPath addCurveToPoint: CGPointMake(3.75, 6.09) controlPoint1: CGPointMake(1.9, 7.02) controlPoint2: CGPointMake(2.64, 6.38)];
        [bezierPath addLineToPoint: CGPointMake(20.03, 1.73)];
        [bezierPath addCurveToPoint: CGPointMake(22.93, 2.46) controlPoint1: CGPointMake(21.25, 1.41) controlPoint2: CGPointMake(22.34, 1.69)];
        [bezierPath addCurveToPoint: CGPointMake(23.27, 4.99) controlPoint1: CGPointMake(23.42, 3.1) controlPoint2: CGPointMake(23.54, 3.99)];
        [bezierPath addLineToPoint: CGPointMake(18.93, 21.26)];
        [bezierPath addCurveToPoint: CGPointMake(16.6, 23.41) controlPoint1: CGPointMake(18.57, 22.61) controlPoint2: CGPointMake(17.7, 23.41)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(21.02, 2.96)];
        [bezierPath addCurveToPoint: CGPointMake(20.39, 3.05) controlPoint1: CGPointMake(20.83, 2.96) controlPoint2: CGPointMake(20.61, 2.99)];
        [bezierPath addLineToPoint: CGPointMake(4.11, 7.4)];
        [bezierPath addCurveToPoint: CGPointMake(2.99, 8.23) controlPoint1: CGPointMake(3.49, 7.57) controlPoint2: CGPointMake(3.09, 7.87)];
        [bezierPath addCurveToPoint: CGPointMake(3.56, 9.53) controlPoint1: CGPointMake(2.89, 8.59) controlPoint2: CGPointMake(3.1, 9.07)];
        [bezierPath addLineToPoint: CGPointMake(15.49, 21.45)];
        [bezierPath addCurveToPoint: CGPointMake(16.6, 22.05) controlPoint1: CGPointMake(15.87, 21.84) controlPoint2: CGPointMake(16.26, 22.05)];
        [bezierPath addCurveToPoint: CGPointMake(17.62, 20.9) controlPoint1: CGPointMake(17.24, 22.05) controlPoint2: CGPointMake(17.52, 21.25)];
        [bezierPath addLineToPoint: CGPointMake(21.96, 4.64)];
        [bezierPath addCurveToPoint: CGPointMake(21.85, 3.29) controlPoint1: CGPointMake(22.11, 4.06) controlPoint2: CGPointMake(22.07, 3.58)];
        [bezierPath addCurveToPoint: CGPointMake(21.02, 2.96) controlPoint1: CGPointMake(21.64, 3.02) controlPoint2: CGPointMake(21.28, 2.96)];
        [bezierPath closePath];
        bezierPath.miterLimit = 4;
        
        [fillColor2 setFill];
        [bezierPath fill];
        
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = UIBezierPath.bezierPath;
        [bezier2Path moveToPoint: CGPointMake(17.92, 15.93)];
        [bezier2Path addCurveToPoint: CGPointMake(17.84, 15.92) controlPoint1: CGPointMake(17.89, 15.93) controlPoint2: CGPointMake(17.86, 15.92)];
        [bezier2Path addCurveToPoint: CGPointMake(17.59, 15.5) controlPoint1: CGPointMake(17.65, 15.87) controlPoint2: CGPointMake(17.54, 15.68)];
        [bezier2Path addLineToPoint: CGPointMake(17.63, 15.37)];
        [bezier2Path addCurveToPoint: CGPointMake(18.04, 15.12) controlPoint1: CGPointMake(17.67, 15.18) controlPoint2: CGPointMake(17.86, 15.08)];
        [bezier2Path addCurveToPoint: CGPointMake(18.29, 15.54) controlPoint1: CGPointMake(18.22, 15.17) controlPoint2: CGPointMake(18.33, 15.36)];
        [bezier2Path addLineToPoint: CGPointMake(18.25, 15.67)];
        [bezier2Path addCurveToPoint: CGPointMake(17.92, 15.93) controlPoint1: CGPointMake(18.21, 15.83) controlPoint2: CGPointMake(18.07, 15.93)];
        [bezier2Path closePath];
        bezier2Path.miterLimit = 4;
        
        [fillColor2 setFill];
        [bezier2Path fill];
        
        
        //// Bezier 3 Drawing
        UIBezierPath* bezier3Path = UIBezierPath.bezierPath;
        [bezier3Path moveToPoint: CGPointMake(16.97, 19.58)];
        [bezier3Path addCurveToPoint: CGPointMake(16.89, 19.57) controlPoint1: CGPointMake(16.94, 19.58) controlPoint2: CGPointMake(16.92, 19.58)];
        [bezier3Path addCurveToPoint: CGPointMake(16.64, 19.16) controlPoint1: CGPointMake(16.7, 19.52) controlPoint2: CGPointMake(16.59, 19.34)];
        [bezier3Path addLineToPoint: CGPointMake(17.37, 16.36)];
        [bezier3Path addCurveToPoint: CGPointMake(17.79, 16.11) controlPoint1: CGPointMake(17.42, 16.17) controlPoint2: CGPointMake(17.6, 16.06)];
        [bezier3Path addCurveToPoint: CGPointMake(18.03, 16.53) controlPoint1: CGPointMake(17.97, 16.16) controlPoint2: CGPointMake(18.08, 16.35)];
        [bezier3Path addLineToPoint: CGPointMake(17.3, 19.33)];
        [bezier3Path addCurveToPoint: CGPointMake(16.97, 19.58) controlPoint1: CGPointMake(17.26, 19.48) controlPoint2: CGPointMake(17.12, 19.58)];
        [bezier3Path closePath];
        bezier3Path.miterLimit = 4;
        
        [fillColor2 setFill];
        [bezier3Path fill];
        
        
        //// Bezier 4 Drawing
        UIBezierPath* bezier4Path = UIBezierPath.bezierPath;
        [bezier4Path moveToPoint: CGPointMake(9.16, 16.77)];
        [bezier4Path addCurveToPoint: CGPointMake(8.67, 16.57) controlPoint1: CGPointMake(8.98, 16.77) controlPoint2: CGPointMake(8.81, 16.7)];
        [bezier4Path addCurveToPoint: CGPointMake(8.67, 15.61) controlPoint1: CGPointMake(8.41, 16.3) controlPoint2: CGPointMake(8.41, 15.87)];
        [bezier4Path addLineToPoint: CGPointMake(13.26, 11.02)];
        [bezier4Path addCurveToPoint: CGPointMake(14.22, 11.02) controlPoint1: CGPointMake(13.52, 10.76) controlPoint2: CGPointMake(13.95, 10.76)];
        [bezier4Path addCurveToPoint: CGPointMake(14.22, 11.99) controlPoint1: CGPointMake(14.49, 11.29) controlPoint2: CGPointMake(14.49, 11.72)];
        [bezier4Path addLineToPoint: CGPointMake(9.64, 16.57)];
        [bezier4Path addCurveToPoint: CGPointMake(9.16, 16.77) controlPoint1: CGPointMake(9.51, 16.7) controlPoint2: CGPointMake(9.33, 16.77)];
        [bezier4Path closePath];
        bezier4Path.miterLimit = 4;
        
        [fillColor2 setFill];
        [bezier4Path fill];
    }


    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)rg_stopImage {
    
    CGSize size = CGSizeMake(18, 18);
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    
    //// Color Declarations
    UIColor* fillColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
    
    //// stop.svg Group
    {
        //// Bezier Drawing
        UIBezierPath* bezierPath = UIBezierPath.bezierPath;
        [bezierPath moveToPoint: CGPointMake(17.74, 13.44)];
        [bezierPath addLineToPoint: CGPointMake(17.74, 13.43)];
        [bezierPath addLineToPoint: CGPointMake(17.75, 13.42)];
        [bezierPath addLineToPoint: CGPointMake(17.75, 13.43)];
        [bezierPath addLineToPoint: CGPointMake(17.74, 13.44)];
        [bezierPath closePath];
        bezierPath.miterLimit = 4;
        
        [fillColor setFill];
        [bezierPath fill];
        
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = UIBezierPath.bezierPath;
        [bezier2Path moveToPoint: CGPointMake(16.84, 12.98)];
        [bezier2Path addLineToPoint: CGPointMake(16.84, 12.98)];
        [bezier2Path addLineToPoint: CGPointMake(16.85, 12.97)];
        [bezier2Path addLineToPoint: CGPointMake(16.85, 12.98)];
        [bezier2Path addLineToPoint: CGPointMake(16.84, 12.98)];
        [bezier2Path closePath];
        bezier2Path.miterLimit = 4;
        
        [fillColor setFill];
        [bezier2Path fill];
        
        
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 18.15, 18.15)];
        [fillColor setFill];
        [rectanglePath fill];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)rg_playImage {
    CGSize size = CGSizeMake(70, 70);
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    
    {
        //// Color Declarations
        UIColor* fillColor2 = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.906];
        UIColor* color = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.392];
        
        {
            //// Bezier 5 Drawing
            UIBezierPath* bezier5Path = UIBezierPath.bezierPath;
            [bezier5Path moveToPoint: CGPointMake(51.54, 36.9)];
            [bezier5Path addLineToPoint: CGPointMake(29.53, 49.61)];
            [bezier5Path addCurveToPoint: CGPointMake(26.25, 47.71) controlPoint1: CGPointMake(28.07, 50.45) controlPoint2: CGPointMake(26.25, 49.39)];
            [bezier5Path addLineToPoint: CGPointMake(26.25, 22.31)];
            [bezier5Path addCurveToPoint: CGPointMake(29.53, 20.42) controlPoint1: CGPointMake(26.25, 20.63) controlPoint2: CGPointMake(28.07, 19.57)];
            [bezier5Path addLineToPoint: CGPointMake(51.53, 33.12)];
            [bezier5Path addCurveToPoint: CGPointMake(51.54, 36.9) controlPoint1: CGPointMake(52.99, 33.96) controlPoint2: CGPointMake(52.99, 36.06)];
            [bezier5Path closePath];
            [color setFill];
            [bezier5Path fill];
            
            
            //// Bezier 6 Drawing
            UIBezierPath* bezier6Path = UIBezierPath.bezierPath;
            [bezier6Path moveToPoint: CGPointMake(26.25, 22.31)];
            [bezier6Path addLineToPoint: CGPointMake(26.25, 47.71)];
            [bezier6Path addCurveToPoint: CGPointMake(26.26, 47.93) controlPoint1: CGPointMake(26.25, 47.78) controlPoint2: CGPointMake(26.25, 47.86)];
            [bezier6Path addCurveToPoint: CGPointMake(29.53, 49.6) controlPoint1: CGPointMake(26.41, 49.48) controlPoint2: CGPointMake(28.13, 50.41)];
            [bezier6Path addLineToPoint: CGPointMake(51.54, 36.9)];
            [bezier6Path addCurveToPoint: CGPointMake(51.53, 33.11) controlPoint1: CGPointMake(52.99, 36.05) controlPoint2: CGPointMake(52.99, 33.95)];
            [bezier6Path addLineToPoint: CGPointMake(29.53, 20.41)];
            [bezier6Path addCurveToPoint: CGPointMake(26.25, 22.31) controlPoint1: CGPointMake(28.07, 19.57) controlPoint2: CGPointMake(26.25, 20.62)];
            [bezier6Path closePath];
            [bezier6Path moveToPoint: CGPointMake(70, 35)];
            [bezier6Path addCurveToPoint: CGPointMake(34.99, 70) controlPoint1: CGPointMake(70, 54.34) controlPoint2: CGPointMake(54.32, 70)];
            [bezier6Path addCurveToPoint: CGPointMake(0, 35) controlPoint1: CGPointMake(15.67, 70) controlPoint2: CGPointMake(0, 54.33)];
            [bezier6Path addCurveToPoint: CGPointMake(35.01, 0) controlPoint1: CGPointMake(0, 15.67) controlPoint2: CGPointMake(15.67, 0)];
            [bezier6Path addCurveToPoint: CGPointMake(70, 35) controlPoint1: CGPointMake(54.33, 0) controlPoint2: CGPointMake(70, 15.67)];
            [bezier6Path closePath];
            [fillColor2 setFill];
            [bezier6Path fill];
        }
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
