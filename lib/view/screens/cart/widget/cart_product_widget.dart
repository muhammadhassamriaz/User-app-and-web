import 'package:flutter/material.dart';
import 'package:flutter_grocery/data/model/response/cart_model.dart';
import 'package:flutter_grocery/helper/price_converter.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/localization/language_constrants.dart';
import 'package:flutter_grocery/provider/cart_provider.dart';
import 'package:flutter_grocery/provider/coupon_provider.dart';
import 'package:flutter_grocery/provider/product_provider.dart';
import 'package:flutter_grocery/provider/splash_provider.dart';
import 'package:flutter_grocery/provider/theme_provider.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/images.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:flutter_grocery/view/base/custom_snackbar.dart';
import 'package:provider/provider.dart';

class CartProductWidget extends StatelessWidget {
  final CartModel cart;
  final int index;
  CartProductWidget({required this.cart, required this.index});

  @override
  Widget build(BuildContext context) {

    String? _variationText = '';
    if(cart.variation !=null ) {
      List<String> _variationTypes = cart.variation!.type!.split('-');
      if(_variationTypes.length == cart.product!.choiceOptions!.length) {
        int _index = 0;
        cart.product!.choiceOptions!.forEach((choice) {
          _variationText = _variationText! + '${(_index == 0) ? '' : ',  '}${choice.title} - ${_variationTypes[_index]}';
          _index = _index + 1;
        });
      }else {
        _variationText = cart.product!.variations![0].type;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_DEFAULT),
      decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            RouteHelper.getProductDetailsRoute(product: cart.product!),
          );
        },
        child: Stack(children: [
          Positioned(
            top: 0, bottom: 0, right: 0, left: 0,
            child: Icon(Icons.delete, color: Colors.white, size: 50),
          ),
          Dismissible(
            key: UniqueKey(),
            onDismissed: (DismissDirection direction) {
              Provider.of<ProductProvider>(context, listen: false).setExistData(null);
              Provider.of<CouponProvider>(context, listen: false).removeCouponData(false);
              Provider.of<CartProvider>(context, listen: false).removeFromCart(index, context);
            },
            child: Container(
              height: 105,
              padding: EdgeInsets.symmetric(vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL, horizontal: Dimensions.PADDING_SIZE_SMALL),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[Provider.of<ThemeProvider>(context).darkTheme ? 900 : 300]!,
                    blurRadius: 5,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FadeInImage.assetNetwork(
                    placeholder: Images.placeholder(context),
                    image: '${Provider.of<SplashProvider>(context, listen: false).baseUrls!.productImageUrl}/${cart.image}',
                    height: 70, width: 85,
                    imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholder(context), height: 70, width: 85,fit: BoxFit.cover),
                  ),
                ),
                SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 2,
                                child: Text(cart.name!,
                                    style: poppinsRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            Text(
                              PriceConverter.convertPrice(context, cart.price),
                              style: poppinsSemiBold.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL),
                            ),
                            SizedBox(width: 10),
                          ],
                        ),

                        Row(children: [
                          Expanded(child: Text('${cart.capacity} ${cart.unit}', style: poppinsRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL))),
                          InkWell(
                            onTap: () {
                              Provider.of<CouponProvider>(context, listen: false).removeCouponData(false);
                              if (cart.quantity! > 1) {
                                Provider.of<CartProvider>(context, listen: false).setQuantity(false, index,showMessage: true, context: context);
                              }else if(cart.quantity == 1){
                                Provider.of<CartProvider>(context, listen: false).removeFromCart(index, context);
                                Provider.of<ProductProvider>(context, listen: false).setExistData(null);
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_SMALL, vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                              child: Icon(Icons.remove, size: 20,color: Theme.of(context).primaryColor),
                            ),
                          ),

                          Text(cart.quantity.toString(), style: poppinsSemiBold.copyWith(fontSize: Dimensions.FONT_SIZE_EXTRA_LARGE,color: Theme.of(context).primaryColor)),

                          InkWell(
                            onTap: () {
                              if(cart.product!.maximumOrderQuantity == null || cart.quantity! < cart.product!.maximumOrderQuantity!) {
                                if(cart.quantity! < cart.stock!) {
                                  Provider.of<CouponProvider>(context, listen: false).removeCouponData(false);
                                  Provider.of<CartProvider>(context, listen: false).setQuantity(true, index, showMessage: true, context: context);
                                }else {
                                  showCustomSnackBar(getTranslated('out_of_stock', context)!, context);
                                }
                              }else{
                                showCustomSnackBar('${getTranslated('you_can_add_max', context)} ${cart.product!.maximumOrderQuantity} ${
                                    getTranslated(cart.product!.maximumOrderQuantity! > 1 ? 'items' : 'item', context)} ${getTranslated('only', context)}', context);
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_SMALL, vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                              child: Icon(Icons.add, size: 20,color: Theme.of(context).primaryColor),
                            ),
                          ),
                        ]),

                        cart.product!.variations!.length > 0 ? Row(children: [
                          Text('${getTranslated('variation', context)}: ', style: poppinsRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL)),

                          Flexible(child: Text(
                            _variationText!,maxLines: 1,
                            style: poppinsRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ]) : SizedBox(),
                      ],
                    )),


                !ResponsiveHelper.isMobile(context) ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_SMALL),
                  child: IconButton(
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false).removeFromCart(index, context);
                      Provider.of<ProductProvider>(context, listen: false).setExistData(null);
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                  ),
                ) : SizedBox(),

              ]),
            ),
          ),
        ]),
      ),
    );
  }
}


class CartProductListView extends StatelessWidget {
  const CartProductListView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          return ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: cartProvider.cartList.length,
            itemBuilder: (context, index) {
              return CartProductWidget(cart: cartProvider.cartList[index], index: index,);
            },
          );
        }
    );
  }
}
