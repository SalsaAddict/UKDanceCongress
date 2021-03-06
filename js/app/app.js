var myApp = angular.module("myApp", ["ngRoute", "facebook", "myServices", "myControllers", "ui.bootstrap"]);

myApp.config(function ($routeProvider, FacebookProvider) {
    $routeProvider
        .when("/Shop", {
            templateUrl: "tpls/Shop.html",
            controller: "ShopController"
        })
        .when("/Shop/:Affiliate", {
            templateUrl: "tpls/Shop.html",
            controller: "ShopController"
        })
        .when("/Basket", {
            templateUrl: "tpls/Basket.html",
            controller: "BasketController"
        })
        .when("/Pass/Add/:Index", {
            templateUrl: "tpls/Pass.html",
            controller: "PassController",
            resolve: { Edit: function () { return false; } }
        })
        .when("/Pass/Edit/:Index", {
            templateUrl: "tpls/Pass.html",
            controller: "PassController",
            resolve: { Edit: function () { return true; } }
        })
        .when("/Package/Add/:Index", {
            templateUrl: "tpls/Package.html",
            controller: "PackageController",
            resolve: { Edit: function () { return false; } }
        })
        .when("/Package/Edit/:Index", {
            templateUrl: "tpls/Package.html",
            controller: "PackageController",
            resolve: { Edit: function () { return true; } }
        })
        .when("/Checkout", {
            templateUrl: "tpls/Checkout.html",
            controller: "CheckoutController"
        })
        .otherwise({
            redirectTo: "/Shop"
        });
    FacebookProvider.init("1376598962611648");
});
