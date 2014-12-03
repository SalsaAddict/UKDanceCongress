var myControllers = angular.module("myControllers", ["ngRoute", "ngStorage", "myServices"]);

myControllers.controller("ShopController", function ($scope, $localStorage, AuthService, ShopService) {
    $scope.Auth = AuthService.Interface;
    $scope.$s = $localStorage;
});

myControllers.controller("BasketController", function ($scope, $localStorage, AuthService, ShopService) {

    $scope.Auth = AuthService.Interface;
    $scope.$s = $localStorage.$default({ Basket: { Packages: [], Passes: [] } });

    $scope.Empty = function () { if ($scope.$s.Basket.Packages.length == 0 && $scope.$s.Basket.Passes.length == 0) return true; else return false; };

    $scope.Price = function () {
        var Items = $scope.$s.Basket.Passes.concat($scope.$s.Basket.Packages)
        var Accommodation = 0, Passes = 0, Dining = 0, Subtotal = 0, Discount = 0, Total = 0
        for (i = 0; i < Items.length; i++) {
            Accommodation += parseFloat(Items[i].Price.Accommodation);
            Passes += parseFloat(Items[i].Price.Passes);
            Dining += parseFloat(Items[i].Price.Dining);
            Subtotal += parseFloat(Items[i].Price.Subtotal);
            Discount += parseFloat(Items[i].Price.Discount);
            Total += parseFloat(Items[i].Price.Total);
        };
        return {
            Accommodation: Accommodation,
            Passes: Passes,
            Dining: Dining,
            Subtotal: Subtotal,
            Discount: Discount,
            Total: Total
        };
    };

});

myControllers.controller("PassController", function ($location, $routeParams, $scope, $localStorage, AuthService, ShopService, Edit) {

    $scope.Auth = AuthService.Interface;
    $scope.$s = $localStorage;

    $scope.Attendee = (!Edit) ? ShopService.CreateAttendee($scope.$s.Products.Passes[$routeParams.Index]) : angular.copy($scope.$s.Basket.Passes[$routeParams.Index]);
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
            a.push(ShopService.CreateAttendee());
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