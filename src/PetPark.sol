//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

    /* ################ TASK SPEC AND ASSUMPTIONS MADE ######################
    1. The Borrowing is only based on On-Chain Data, no ERC721 or other Tokens need to be transferred
    2. The Ownable functionality must be coded and not based on a library like OpenZeppelin
       ################ END TASK SPEC AND ASSUMPTIONS #######################*/ 

contract PetPark {
    //address of Contract owner
    address owner;
    // Constant for zero animal count
    uint8 internal constant NO_ANIMAL = 0;
    // Mapping of address to User profile data
    mapping(address => ProfileData) Profiles;
    // Mapping to keep track of what animal is borrowed per address
    mapping(address => uint8) WhoBorrowedWhat;
    // Mapping to keep track of animals in PetPark
    mapping(AnimalType => uint256) PetParkData;
    // Mapping to keep track that users can't borrow more animals than are sheltered
    mapping(AnimalType => uint256) animalBorrowCounter;

    // Enum for Gender as per spec in task
    enum Gender{
        Male,
        Female
    }

    // Struct to Hold user details as they Borrow
    struct ProfileData{
        uint256 age;
        Gender gender;
    }

    // Enum to hold AnimalTypes, 0 is set to None 
    enum AnimalType{
        None,
        Fish,
        Cat,
        Dog,
        Rabbit,
        Parrot
    }

    // Will set the owner of the contract as the deployer
    constructor() {
        owner = msg.sender;
    }

    /// ERRORS

    error NotOwner();

    /// EVENTS
    event Added(AnimalType indexed _animalType, uint256 _animalCount);
    event Borrowed(AnimalType indexed _animalType);
    event Returned(AnimalType indexed _animalType);

    /// MODIFIERS
    modifier onlyOwner(){
        if(msg.sender != owner){
            revert NotOwner();
        }
        _;
    }

    modifier onlyEligible(uint256 _age,Gender _gender,AnimalType _animalType){
        // Check the animal type is not invalid
        require(_animalType!= AnimalType.None,"Invalid animal type");

        // Check the age is above zero
        require(_age>0,"must be older than Zero");

        // Load user profile
        ProfileData memory _profileData = Profiles[msg.sender];
        // Zero age will mean it's a new profile
        if(_profileData.age == 0)
        {
            _profileData.age = _age;
            _profileData.gender = _gender;
            // Add Profile to storage
            Profiles[msg.sender] = _profileData;
        }else{
            // THIS MEANS IT'S AN EXISTING PROFILE
            require(_profileData.age == _age,"Invalid Age");            
            require(_profileData.gender == _gender,"Invalid Gender");
        }
        // internal function to check animal counts
        _checkAnimalCount(_animalType);

        if(_gender == Gender.Male){
            require((_animalType == AnimalType.Dog) || (_animalType== AnimalType.Fish),
                "Invalid animal for men");
        }else{
            require(_animalType == AnimalType.Cat && _age > 40,"Invalid animal for women under 40");
        }
        
        // continue
        _;
    }

    // modifier to check the user has an adopted animal so they can't give back an animal they did
    // not adopt
    modifier hasBorrow(){
        require(WhoBorrowedWhat[msg.sender] > NO_ANIMAL,"No borrowed pets");
        _;
    }

    /// INTERNAL FUNCTIONS

    function _checkAnimalCount(AnimalType _animalType) internal {
        // make sure the user is not currently adopting an animal
        require(WhoBorrowedWhat[msg.sender] == NO_ANIMAL,"Already adopted a pet");
        // Check the park actually has animals of this type
        require(PetParkData[_animalType] != NO_ANIMAL,"Selected animal not available");
        // check they have not been adopted already
        require(PetParkData[_animalType] >= animalBorrowCounter[_animalType] + 1 ,"Selected animal not available");
    }

    /// EXTERNAL FUNCTIONS
    function add(AnimalType _animalType,uint256 _amountOfAnimals) external onlyOwner {
        // Make sure the owner is not trying to add an invlaid animal
        require(_animalType!= AnimalType.None,"Invalid animal");
        // make sure they animal count is greater than zero
        if(_amountOfAnimals > 0){
            PetParkData[_animalType] += _amountOfAnimals;
        }
        // emit the Added event
        emit Added(_animalType,_amountOfAnimals);
    }

    function borrow(uint256 _age,Gender gender,AnimalType _animalType) external onlyEligible(_age,gender,_animalType){
        // add the adopting to the mapping in storage
        WhoBorrowedWhat[msg.sender] = uint8(_animalType);
        // increment the adopted animal count
        animalBorrowCounter[_animalType] += 1;
        // emit the Borrowed event
        emit Borrowed(_animalType);
    }

    // Modifier checks the user actually has an adoption to give back
    function giveBackAnimal() external hasBorrow{
        // check what animal they adopted
        AnimalType _animalToGiveBack = AnimalType(WhoBorrowedWhat[msg.sender]);
        // Remove the animal from the mapping for this user
        WhoBorrowedWhat[msg.sender] = NO_ANIMAL;
        // decrement the adoption count for this animal type
        animalBorrowCounter[_animalToGiveBack] -= 1;
        // emit the Returned event
        emit Returned(_animalToGiveBack);
    }

    // VIEW FUNCTIONS
    function animalCounts(AnimalType _animalType) external view returns (uint256 count){
        // the count is equal to the amount of animals the park has minus the amount of animals adopted
        count = PetParkData[_animalType] - animalBorrowCounter[_animalType];
    }
    
}
