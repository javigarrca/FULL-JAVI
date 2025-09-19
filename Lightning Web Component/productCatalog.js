import { LightningElement, track, wire } from 'lwc';
import getActivePricebooks from '@salesforce/apex/ProductCatalogController.getActivePricebooks';
import getProductsByPricebookId from '@salesforce/apex/ProductCatalogController.getProductsByPricebookId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class ProductCatalog extends LightningElement {
    @track pricebooks = [];
    @track selectedPricebookId;
    @track products = [];
    @track error;
    @track showPayment = false; // por defecto, no se mostrará hasta que el usuario haga clic en "Comprar"

    // Producto seleccionado para ver en detalle
    @track selectedProductFull = null;

    @wire(getActivePricebooks)
    wiredPricebooks({ data, error }) {
        if (data) {
            this.pricebooks = data.map((pb, index) => ({
                label: pb.Name,
                value: pb.Id,
                checked: index === 0
            }));
            this.selectedPricebookId = this.pricebooks[0]?.value;
            this.loadProducts();
        } else if (error) {
            this.error = error.body?.message || error.message;
        }
    }

    loadProducts() {
        if (!this.selectedPricebookId) return;
        getProductsByPricebookId({ pricebookId: this.selectedPricebookId })
            .then(data => {
                this.products = data.map(p => ({
                    Id: p.Id,
                    ProductName: p.Product2.Name,
                    Description: p.Product2.Description || '',
                    // Recorte solo para la vista de catálogo
                    ShortDescription: p.Product2.Description 
                        ? (p.Product2.Description.length > 200 
                            ? p.Product2.Description.substring(0, 200) + '...' 
                            : p.Product2.Description) 
                        : '',
                    UnitPrice: p.UnitPrice
                }));
                this.error = undefined;
            })
            .catch(err => {
                this.error = err.body?.message || err.message;
                this.products = [];
            });
    }

    handlePricebookChange(event) {
        this.selectedPricebookId = event.target.value;
        this.pricebooks = this.pricebooks.map(pb => ({
            ...pb,
            checked: pb.value === this.selectedPricebookId
        }));
        this.loadProducts();
    }

    // Abrir producto en modo detalle completo
    handleAddClick(event) {
        const productId = event.target.dataset.id;
        this.selectedProductFull = this.products.find(p => p.Id === productId);
    }

    // Volver al catálogo
    handleCloseDetail() {
        this.selectedProductFull = null;
    }
    /*handleBuyClick() {
        // toast de compra realizada
        const event = new ShowToastEvent({
            title: 'Compra realizada',
            message: `Has comprado el producto: ${this.selectedProductFull.ProductName} por ${this.selectedProductFull.UnitPrice} €`,
            variant: 'success'
        });
        this.dispatchEvent(event);
    }*/
   handleBuyClick() {
        // Mostrar toast verde indicando que el artículo se añadió correctamente
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Artículo añadido',
                message: `${this.selectedProductFull.ProductName} se ha añadido correctamente.`,
                variant: 'success', // verde
                mode: 'pester' // desaparece automáticamente tras unos segundos
            })
        );
        this.showPayment = true; // Mostrar la sección de pago
    }
}
