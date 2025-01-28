@EndUserText.label: 'Custom entity for products from ES5'
@ObjectModel.query.implementedBy: 'ABAP:ZRAP620_CL_CE_PRODUCTS_RJ'
define custom entity ZRAP620_CE_PRODUCTS_RJ
// with parameters parameter_name : parameter_type
{
  key  Product : abap.char(10);
  ProductCategory : abap.char(40);
  Supplier : abap.char(10);
  
}
