var myControllers = angular.module("myControllers", ["ngRoute", "ngStorage", "myServices"]);

myControllers.controller("AuthController", function ($scope, $localStorage, AuthService, ShopService) {

    $scope.ShopLogin = function () {
        AuthService.Interface.Login();
        ShopService.RefreshPrices();
    };

    $scope.ShopLogout = function () {
        AuthService.Interface.Logout();
        ShopService.RefreshPrices();
    };

});

myControllers.controller("ShopController", function ($scope, $localStorage, AuthService, ShopService) {
    $scope.Auth = AuthService.Interface;
    $scope.$s = $localStorage;
    $scope.FullPassPackageDiscount = function () { return ShopService.FullPassPackageDiscount(); }
});

myControllers.controller("BasketController", function ($scope, $localStorage, AuthService, ShopService) {

    $scope.Auth = AuthService.Interface;
    $scope.$s = $localStorage.$default({ Basket: { Packages: [], Passes: [] } });

    $scope.Empty = function () { if ($scope.$s.Basket.Packages.length == 0 && $scope.$s.Basket.Passes.length == 0) return true; else return false; };

    $scope.Price = function () { return ShopService.Total(); };

    $scope.RemovePass = function (Pass) {
        var i = $scope.$s.Basket.Passes.indexOf(Pass);
        $scope.$s.Basket.Passes.splice(i, 1);
    };

    $scope.RemovePackage = function (Package) {
        var i = $scope.$s.Basket.Packages.indexOf(Package);
        $scope.$s.Basket.Packages.splice(i, 1);
    };

});

myControllers.controller("CheckoutController", function ($scope, $localStorage, AuthService, ShopService) {

    $scope.Auth = AuthService.Interface;
    $scope.$s = $localStorage;

});

myControllers.controller("PassController", function ($location, $routeParams, $scope, $localStorage, AuthService, ShopService, Edit) {

    $scope.Auth = AuthService.Interface;
    $scope.$s = $localStorage;

    $scope.Attendee = (!Edit) ? ShopService.CreateAttendee($scope.$s.Products.Passes[$routeParams.Index], null) : angular.copy($scope.$s.Basket.Passes[$routeParams.Index]);
    $scope.Price = function () { return ShopService.Price($scope.Attendee); };

    $scope.Save = function () {
        $scope.Attendee.Price = $scope.Price();
        if (!Edit) { $scope.$s.Basket.Passes.push($scope.Attendee); }
        else { $scope.$s.Basket.Passes[$routeParams.Index] = $scope.Attendee; };
        $location.path("/Shop")
    };

});

myControllers.controller("PackageController", function ($location, $routeParams, $scope, $localStorage, AuthService, ShopService, Edit) {

    $scope.Auth = AuthService.Interface;
    $scope.$s = $localStorage;

    $scope.Package = (!Edit) ? ShopService.CreatePackage($scope.$s.Products.Packages[$routeParams.Index]) : angular.copy($scope.$s.Basket.Packages[$routeParams.Index]);
    $scope.Price = function () { return ShopService.Price($scope.Package); };

    $scope.AddGuest = function () {
        var a = $scope.Package.Attendees;
        if (a.length < $scope.Package.Package.Max) {
            a.push(ShopService.CreateAttendee(a[a.length - 1].Pass, a[a.length - 1].Dining));
            a[a.length - 1].Active = true;
        };
    };

    $scope.RemoveGuest = function (i) {
        var a = $scope.Package.Attendees;
        if (a.length > $scope.Package.Package.Min) {
            a.splice(i, 1);
            a[i].Active = true;
        };
    };

    $scope.Save = function () {
        $scope.Package.Price = $scope.Price();
        if (!Edit) { $scope.$s.Basket.Packages.push($scope.Package); }
        else { $scope.$s.Basket.Packages[$routeParams.Index] = $scope.Package; };
        $location.path("/Shop")
    };

});