require 'test_helper'

class PrikeysControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:prikeys)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create prikey" do
    assert_difference('Prikey.count') do
      post :create, :prikey => { }
    end

    assert_redirected_to prikey_path(assigns(:prikey))
  end

  test "should show prikey" do
    get :show, :id => prikeys(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => prikeys(:one).to_param
    assert_response :success
  end

  test "should update prikey" do
    put :update, :id => prikeys(:one).to_param, :prikey => { }
    assert_redirected_to prikey_path(assigns(:prikey))
  end

  test "should destroy prikey" do
    assert_difference('Prikey.count', -1) do
      delete :destroy, :id => prikeys(:one).to_param
    end

    assert_redirected_to prikeys_path
  end
end
