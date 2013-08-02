require 'test_helper'

class PricesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:prices)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create price" do
    assert_difference('Price.count') do
      post :create, :price => { }
    end

    assert_redirected_to price_path(assigns(:price))
  end

  test "should show price" do
    get :show, :id => prices(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => prices(:one).to_param
    assert_response :success
  end

  test "should update price" do
    put :update, :id => prices(:one).to_param, :price => { }
    assert_redirected_to price_path(assigns(:price))
  end

  test "should destroy price" do
    assert_difference('Price.count', -1) do
      delete :destroy, :id => prices(:one).to_param
    end

    assert_redirected_to prices_path
  end
end
