//
//  ViewController.m
//  snapshotter
//
//  Created by Gershon Kagan on 6/28/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ViewController.h"
#import "MatchModel.h"
@import MobileCoreServices;

NSString *imageMediaType;

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(weak, nonatomic) IBOutlet UIButton *pickPhotoButton;
@property(weak, nonatomic) IBOutlet UIButton *openURLButton;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(weak, nonatomic) IBOutlet UILabel *resultantJsonLabel;

@property(strong, nonatomic) NSString *topMediaURLString;

@end


@implementation ViewController

// MARK: - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    imageMediaType = (NSString *)kUTTypeImage;
}

// MARK: - Handlers

- (IBAction)pickPhoto {
    NSLog(@"pickPhoto tapped");
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        _resultantJsonLabel.text = [NSString stringWithFormat:@"ERROR sourceType:%ld unavailable", (long)sourceType];
        return;
    }
    if (![[UIImagePickerController availableMediaTypesForSourceType:sourceType] containsObject:imageMediaType]) {
        _resultantJsonLabel.text = [NSString stringWithFormat:@"ERROR unvailableMediaType:%@  forSourceType:%ld", imageMediaType, (long)sourceType];
        return;
    }
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.mediaTypes = @[imageMediaType]; // Defaults to image type.
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil]; // ^{}
}

- (IBAction)openURL {
    if (_topMediaURLString.length) {
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_topMediaURLString]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_topMediaURLString] options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @NO} completionHandler:nil];
    }
}

// MARK: - Helper

- (void)lower {
    NSLog(@"%@", _resultantJsonLabel.text);
    [self dismissViewControllerAnimated:YES completion:nil];
}

// MARK: - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString *returnedMediaType = info[UIImagePickerControllerMediaType];
    if ([returnedMediaType isEqualToString:imageMediaType]) {
        UIImage *pickedImage = info[UIImagePickerControllerEditedImage];
        if (pickedImage == nil) {
            pickedImage = info[UIImagePickerControllerOriginalImage];
        }
        if (pickedImage == nil) {
            _resultantJsonLabel.text = [NSString stringWithFormat:@"ERROR EditedImage and OriginalImage are nil\n\n%@", info.description];
        } else {
            _resultantJsonLabel.text = [NSString stringWithFormat:@"image size:%@  scale:%.1f\n\n%@", NSStringFromCGSize(pickedImage.size), pickedImage.scale, info.description];
            [_activityIndicator startAnimating];
            [[MatchModel shared] matchImage:pickedImage completion:^(NSArray<ClarifaiSearchResult *> *results, NSError *error) {
                ClarifaiSearchResult *topResult = results.firstObject;
                if (topResult && topResult.mediaURL) {
                    self.topMediaURLString = topResult.mediaURL;
                } else {
                    self.topMediaURLString = nil;
                }
                NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:1024];
                [outputString setString:_resultantJsonLabel.text];
                [outputString appendFormat:@"%@\n\nerror:%@\nresults:%@\n\n", _resultantJsonLabel.text, error, results];
                for (ClarifaiSearchResult *searchResult in results) {
                    NSMutableString *conceptNames = [[NSMutableString alloc] init];
                    [conceptNames setString:@""];
                    for (ClarifaiConcept *concept in searchResult.concepts) {
                        [conceptNames appendFormat:@"%@, ", concept.conceptName];
                    }
                    [outputString appendFormat:@"score:%@  inputID:%@  conceptNames:%@  concepts:%@  mediaURL:%@  creationDate:%@  mediaData:%@  location:%@  metadata:%@\n", searchResult.score, searchResult.inputID, conceptNames, searchResult.concepts, searchResult.mediaURL, searchResult.creationDate, searchResult.mediaData, searchResult.location, searchResult.metadata];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_activityIndicator stopAnimating];
                    _resultantJsonLabel.text = outputString;
                    NSLog(@"%@", outputString);
                });
            }];
        }
    } else {
        _resultantJsonLabel.text = [NSString stringWithFormat:@"ERROR returnedMediaType:%@ not equal to:%@\n\n%@", returnedMediaType, imageMediaType, info.description];
    }
    [self lower];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    _resultantJsonLabel.text = @"C'mon. Pick a photo. 😀";
    [self lower];
}

@end
