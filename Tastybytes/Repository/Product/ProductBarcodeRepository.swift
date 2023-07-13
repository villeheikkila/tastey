import Supabase

protocol ProductBarcodeRepository {
    func getByProductId(id: Int) async -> Result<[ProductBarcode.JoinedWithCreator], Error>
    func addToProduct(product: Product.Joined, barcode: Barcode) async -> Result<Barcode, Error>
    func delete(id: Int) async -> Result<Void, Error>
}

struct SupabaseProductBarcodeRepository: ProductBarcodeRepository {
    let client: SupabaseClient

    func getByProductId(id: Int) async -> Result<[ProductBarcode.JoinedWithCreator], Error> {
        do {
            let response: [ProductBarcode.JoinedWithCreator] = try await client
                .database
                .from(ProductBarcode.getQuery(.tableName))
                .select(columns: ProductBarcode.getQuery(.joinedCreator(false)))
                .eq(column: "product_id", value: id)
                .execute()
                .value

            return .success(response)
        } catch {
            return .failure(error)
        }
    }

    func addToProduct(product: Product.Joined, barcode: Barcode) async -> Result<Barcode, Error> {
        do {
            try await client
                .database
                .from(ProductBarcode.getQuery(.tableName))
                .insert(values: ProductBarcode.NewRequest(product: product, barcode: barcode), returning: .representation)
                .execute()

            return .success(barcode)
        } catch {
            return .failure(error)
        }
    }

    func delete(id: Int) async -> Result<Void, Error> {
        do {
            try await client
                .database
                .from(ProductBarcode.getQuery(.tableName))
                .delete()
                .eq(column: "id", value: id)
                .execute()

            return .success(())
        } catch {
            return .failure(error)
        }
    }
}