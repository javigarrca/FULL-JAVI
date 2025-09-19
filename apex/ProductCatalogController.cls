public with sharing class ProductCatalogController {

    /**
     * Devuelve todas las listas de precio (Pricebook2) activas.
     */
    @AuraEnabled(cacheable=true)
    public static List<Pricebook2> getActivePricebooks() {
        return [
            SELECT Id, Name
            FROM Pricebook2
            WHERE IsActive = true
            ORDER BY Name
        ];
    }

    /**
     * Obtiene los productos (PricebookEntry) activos de un Pricebook concreto.
     * @param pricebookId Id del Pricebook seleccionado.
     * @return Lista de PricebookEntry con datos de producto y precio.
     */
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProductsByPricebookId(Id pricebookId) {
        if (pricebookId == null) {
            throw new AuraHandledException('Debe indicar el Id del Price Book.');
        }

        return [
            SELECT Id,
                   Name,
                   UnitPrice,
                   IsActive,
                   Product2.Id,
                   Product2.Name,
                   Product2.Description,
                   Pricebook2.Name
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId
              AND IsActive = true
            ORDER BY Product2.Name
        ];
    }

    /**
     * Añade un producto (PricebookEntry) a una Opportunity existente.
     * @param oppId Id de la Opportunity.
     * @param pricebookEntryId Id del PricebookEntry (producto con precio).
     * @param quantity Cantidad del producto.
     * @return Id del OpportunityLineItem creado.
     */
    // Falta por definir como añadir los productos...
    @AuraEnabled
    /*public static Id addProductToOpportunity(Id oppId, Id pricebookEntryId, Decimal quantity) {
        if (oppId == null || pricebookEntryId == null || quantity == null || quantity <= 0) {
            throw new AuraHandledException('Debe indicar Opportunity, producto y cantidad válidos.');
        }

        // Obtener el precio unitario del producto
        PricebookEntry pbe = [
            SELECT UnitPrice
            FROM PricebookEntry
            WHERE Id = :pricebookEntryId
            LIMIT 1
        ];

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oppId,
            PricebookEntryId = pricebookEntryId,
            Quantity = quantity,
            TotalPrice = quantity * pbe.UnitPrice
        );
        insert oli;

        return oli.Id;
    }*/
}
