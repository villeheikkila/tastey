import Models
import Supabase

struct SupabaseCategoryRepository: CategoryRepository {
    let client: SupabaseClient

    func getAllWithSubcategoriesServingStyles() async
    -> Result<[Models.Category.JoinedSubcategoriesServingStyles], Error> {
        do {
            let response: [Models.Category.JoinedSubcategoriesServingStyles] = try await client
                .database
                .from(.categories)
                .select(columns: Models.Category.getQuery(.joinedSubcaategoriesServingStyles(false)))
                .order(column: "name")
                .execute()
                .value

            return .success(response)
        } catch {
            return .failure(error)
        }
    }

    func insert(newCategory: Category.NewRequest) async -> Result<Void, Error> {
        do {
            try await client
                .database
                .from(.categories)
                .insert(values: newCategory, returning: .representation)
                .execute()

            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func addServingStyle(categoryId: Int, servingStyleId: Int) async -> Result<Void, Error> {
        do {
            try await client
                .database
                .from(.servingStyles)
                .insert(values: Category.NewServingStyleRequest(categoryId: categoryId, servingStyleId: servingStyleId))
                .execute()

            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func deleteServingStyle(categoryId: Int, servingStyleId: Int) async -> Result<Void, Error> {
        do {
            try await client
                .database
                .from(.servingStyles)
                .delete()
                .eq(column: "category_id", value: categoryId)
                .eq(column: "serving_style_id", value: servingStyleId)
                .execute()

            return .success(())
        } catch {
            return .failure(error)
        }
    }
}