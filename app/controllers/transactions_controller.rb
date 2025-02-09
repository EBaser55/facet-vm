class TransactionsController < ApplicationController
  def index
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 50).to_i
    per_page = 50 if per_page > 50
    
    scope = TransactionReceipt.newest_first
    
    if params[:block_number].present?
      scope = scope.where(block_number: params[:block_number])
    end
    
    if params[:from].present?
      scope = scope.where(from_address: params[:from].downcase)
    end
    
    if params[:to].present?
      scope = scope.where(effective_contract_address: params[:to].downcase)
    end
    
    if params[:to_or_from].present?
      to_or_from = params[:to_or_from].downcase
      scope = scope.where(
        "from_address = :addr OR effective_contract_address = :addr",
        addr: to_or_from
      )
    end
    
    cache_key = ["transactions_index", scope, page, per_page]
  
    result = Rails.cache.fetch(cache_key) do
      res = scope.page(page).per(per_page).to_a
      convert_int_to_string(res)
    end
  
    render json: {
      result: result,
      count: scope.count
    }
  end

  def show
    transaction = TransactionReceipt.find_by(transaction_hash: params[:id])

    if transaction.blank?
      render json: { error: "Transaction not found" }, status: 404
      return
    end

    render json: {
      result: convert_int_to_string(transaction)
    }
  end

  def total
    transaction_count = TransactionReceipt.count
    unique_from_address_count = TransactionReceipt.distinct.count(:from_address)
    
    result = {
      transaction_count: transaction_count,
      unique_from_address_count: unique_from_address_count
    }
    
    render json: {
      result: convert_int_to_string(result)
    }
  end
end
