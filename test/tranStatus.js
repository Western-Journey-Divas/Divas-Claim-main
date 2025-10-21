require('dotenv').config(); // .env 파일을 사용하기 위해 dotenv 패키지 로드
const { ethers } = require('ethers'); // ethers.js 라이브러리 임포트

async function getTransactionStatus(transactionHash) {
    const rpcUrl = process.env.APP_ETHERMAIN_RPC_URL;
    const provider = new ethers.JsonRpcProvider(rpcUrl); // 네트워크 URL을 입력하세요
    const transaction = await provider.getTransaction(transactionHash);
    
    if (!transaction) {
        console.log('트랜잭션을 찾을 수 없습니다.');
        return;
    }
    console.log(transaction);

    if (transaction.blockNumber === 0) {
        console.log(`트랜잭션 해시: ${transactionHash}, 상태: 대기 중 (Pending)`); // Pending 상태
    } else {
        const receipt = await provider.getTransactionReceipt(transactionHash);
        const status = receipt.status === 1 ? '성공' : '실패'; // 상태 확인
        console.log(`트랜잭션 해시: ${transactionHash}, 상태: ${status}`); // 결과 출력
    }
}

// 커맨드라인 인자로 트랜잭션 해시를 받기
const transactionHash = process.argv[2];

if (!transactionHash) {
    console.log('트랜잭션 해시를 입력하세요.');
    process.exit(1);
}

getTransactionStatus(transactionHash);