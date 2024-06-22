<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>L4S Test Tool</title>
        <link href="/css/bootstrap.min.css" rel="stylesheet">
        <link src="js/bootstrap.min.js">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
    </head>
    <body style="padding-left: 20%; padding-right:20%" >
        

        <nav class="navbar navbar-expand-md navbar-dark fixed-top bg-dark">
            <div class="container-fluid">
                <a class="navbar-brand" href="index.php">L4S Test Kit</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarCollapse" aria-controls="navbarCollapse" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarCollapse">
                    <ul class="navbar-nav me-auto mb-2 mb-md-0">
                        <li class="nav-item">
                            <a class="nav-link" aria-current="page" href="wearables.php">Wearables</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="dicom.php">Dicom</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="consultation.php">Consultation</a>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>
        <div class="container" >
            <div class="row">
                <img src="Images/StartButton.png" style="width: 600px;height: 600px"  alt="alt"/>
            </div>
        </div>

   <?php include './Includes/footer.php'; ?>
    <script src="js/bootstrap.min.js"></script>
</body>
</html>
