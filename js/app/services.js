var myServices = angular.module("myServices", ["ngRoute", "ngStorage", "facebook"]);

myServices.service("AuthService", ["$route", "$routeParams", "$localStorage", "$http", "Facebook", function ($route, $routeParams, $localStorage, $http, Facebook) {

    var $s = $localStorage, _this = this;

    Facebook.getLoginStatus(function (response) { _this.ProcessAuthResponse(response); });

    this.ProcessAuthResponse = function (authResponse) {
        if (authResponse.status === "connected") {
            Facebook.api("/me", function (userResponse) {
                $http.post("run.ashx?Login", userResponse).success(function (data) {
                    if (data.User) {
                        $s.User = data.User;
                        if (data.Affiliate) { $s.Affiliate = data.Affiliate };
                    } else delete $s.User;
                });
            });
        } else delete $s.User;
        if ($routeParams.Affiliate) {
            var Affiliate = $routeParams.Affiliate;
            if ($s.User && $s.User.Affiliate) {
                if (Affiliate != $s.User.Affiliate) {
                    $route.updateParams({ Affiliate: $s.User.Affiliate });
                    $route.reload();
                    $location.path($location.path())
                };
            }
            else $http.get("run.ashx?Affiliate&Code=" + Affiliate).success(function (data) { $s.Affiliate = data.Affiliate; });
        };
    };

    this.Interface = {
        Login: function () { Facebook.login(function (authResponse) { _this.ProcessAuthResponse(authResponse); }); },
        Logout: function () { Facebook.logout(); delete $s.User; },
        IsOrganiser: function () { return ($s.User && $s.User.IsOrganiser == 1) ? true : false; },
        IsAffiliate: function () { return ($s.User && $s.Affiliate && $s.User.Affiliate == $s.Affiliate.Code) ? true : false; }
    };

}]);

myServices.service("ShopService", ["$localStorage", "$http", "AuthService", function ($localStorage, $http, AuthService) {

    var $s = $localStorage.$default({ Genders: [], Products: { Packages: [], Passes: [], Dining: [] } });

    $http.get("run.ashx?Genders").success(function (data) { $s.Genders = data.Genders });
    $http.get("run.ashx?Products&Type=K").success(function (data) { $s.Products.Packages = data.Products });
    $http.get("run.ashx?Products&Type=P").success(function (data) { $s.Products.Passes = data.Products });
    $http.get("run.ashx?Products&Type=D").success(function (data) { $s.Products.Dining = data.Products });

    this.CreateAttendee = function (Product) {
        return {
            Forename: null,
            Surname: null,
            Gender: null,
            Pass: (Product) ? Product : $s.Products.Passes[0],
            Dining: null,
            Active: false
        };
    };

    this.CreatePackage = function (Product) {
        var Package = { Package: Product, Attendees: [] };
        for (i = 0; i < Product.Min; i++) { Package.Attendees.push(this.CreateAttendee(null)); };
        Package.Attendees[0].Active = true;
        return Package;
    };

    this.FullPassPackageDiscount = function () {
        if (AuthService.Interface.IsAffiliate()) {
            return 10;
        }
        else {
            return 0;
        };
    };

    this.Price = function (Item) {
        var Accommodation = (Item.Package) ? parseFloat(Item.Package.CurrentPrice) : 0;
        var Attendees = (Item.Package) ? Item.Attendees : [Item];
        var Passes = 0, Dining = 0, Discount = 0;
        for (i = 0; i < Attendees.length; i++) {
            var Attendee = Attendees[i];
            if (Attendee.Pass) { Passes += parseFloat(Attendee.Pass.CurrentPrice); };
            if (Attendee.Dining) { Dining += parseFloat(Attendee.Dining.CurrentPrice); };
            if (Item.Package && Attendee.Pass && Attendee.Pass.Name == "Full Pass") { Discount += this.FullPassPackageDiscount() };
        };
        var Subtotal = Accommodation + Passes + Dining;
        var Total = Subtotal - Discount;
        return {
            Accommodation: Accommodation,
            Passes: Passes,
            Dining: Dining,
            Subtotal: Subtotal,
            Discount: Discount,
            Total: Total
        };
    };

}]);
