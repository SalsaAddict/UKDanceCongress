var myApp = angular.module("myApp", ["ngRoute", "facebook", "myServices", "myControllers"]);

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
        .when("/Pass", {
            templateUrl: "tpls/Pass.html",
            controller: "PassController"
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
        .when("/Package", {
            templateUrl: "tpls/Package.html",
            controller: "PackageController"
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
        .otherwise({
            redirectTo: "/Shop"
        });
    FacebookProvider.init("1376598962611648");
});
