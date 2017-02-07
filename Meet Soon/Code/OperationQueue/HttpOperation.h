/**
 *    @file            HTTPOperationUtils.h
 *    @author            
 *    @date            
 *    @version        
 *    @description     
 *    @copyright        
 *    @brief
 */


@interface HttpOperation : NSOperation

//to create a HttpOperationUtils and use Queue,you should assign url,invokeObject and invoke property.
@property(retain,nonatomic) NSMutableDictionary *parameters;

- (void)setParameter:(NSMutableDictionary *)para;
@end