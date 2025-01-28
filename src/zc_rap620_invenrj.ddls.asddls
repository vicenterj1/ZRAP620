@Metadata.allowExtensions: true
//@EndUserText.label: '###GENERATED Core Data Service Entity'
@EndUserText.label: 'Projection View for Inventory'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_RAP620_INVENRJ
  provider contract transactional_query
  as projection on ZR_RAP620_INVENRJ
{
  key Uuid,
  InventoryId,
  @Consumption.valueHelpDefinition: [{  
    entity: {
        name: 'ZRAP620_CE_PRODUCTS_RJ',
        element: 'Product'},
    useForValidation: true} ]
  ProductId,
  Quantity,
  @Semantics.unitOfMeasure: true
  @Consumption.valueHelpDefinition: [ {
      entity: {
        name: 'I_UnitOfMeasure',
        element: 'UnitOfMeasure'
      }
      } ]
  QuantityUnit,
  Price,
  @Semantics.currencyCode: true
  @Consumption.valueHelpDefinition: [ {
      entity: {
        name: 'I_Currency',
        element: 'Currency'
      }
      } ]
  CurrencyCode,
  Description,
  OverallStatus,
  CreatedBy,
  CreatedAt,
  LastChangedBy,
  LastChangedAt,
  LocalLastChangedAt
  
}
